// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

@MainActor final class AppEnvironment: ObservableObject {
    let workspace: Workspace?
    @Published var state = WorkspaceState()
    @Published var error: String?
    @Published var busy = 0
    @Published var deviceSnapshot: SystemSnapshot?
    @Published var deviceBackups: [SystemBackup] = []
    @Published var systemError: String?
    @Published var respringing = false
    @Published var systemRecoveryPending = false
    var deviceStore: SystemConfigurationStore?
    var deviceLinks: [UUID: SystemSnapshot] = [:]
    @Published var fieldIndex: [FieldSearchResult] = []
    init() {
        do {
            let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            var root = base.appendingPathComponent("Elyra", isDirectory: true)
            #if DEBUG
            // UI tests use a fresh, isolated sandbox. No user library is erased or seeded.
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "-ElyraTestWorkspace"), args.indices.contains(index + 1),
               let id = UUID(uuidString: args[index + 1]) {
                root = base.appendingPathComponent("ElyraUITests", isDirectory: true).appendingPathComponent(id.uuidString, isDirectory: true)
            }
            #endif
            workspace = try Workspace(root: root)
            systemRecoveryPending = FileManager.default.fileExists(atPath: root.appendingPathComponent("SystemBackups/pending.json").path)
        } catch { workspace = nil; self.error = error.localizedDescription }
    }
    func refresh() async {
        guard let workspace else { return }
        state = await workspace.listing()
        var fields: [FieldSearchResult] = []
        for record in state.documents {
            do {
                let snapshot = try await workspace.snapshot(record.id)
                let remaining = max(0, 100_000 - fields.count)
                let indexed = await Task.detached(priority: .utility) { () -> [FieldSearchResult] in
                    let extra = snapshot.value.value(at: ["CacheExtra"]) ?? snapshot.value
                    var entries: [FieldSearchResult] = []
                    func walk(_ node: PlistValue, prefix: [String], depth: Int = 0) {
                        guard depth < 64 else { return }
                        for (key, value) in node.children {
                            guard entries.count < remaining else { return }
                            let path = prefix + [key]
                            entries.append(FieldSearchResult(document: record.id, name: record.name, key: key, path: path))
                            walk(value, prefix: path, depth: depth + 1)
                        }
                    }
                    walk(extra, prefix: snapshot.value.value(at: ["CacheExtra"]) == nil ? [] : ["CacheExtra"])
                    return entries
                }.value
                fields += indexed
            } catch { self.error = error.localizedDescription }
        }
        fieldIndex = fields
    }
    func run(_ action: @escaping @MainActor (Workspace) async throws -> Void) {
        guard let workspace else { error = "Workspace could not be opened. Export existing files before attempting recovery."; return }
        busy += 1
        Task {
            defer { busy -= 1 }
            do { try await action(workspace) } catch { self.error = error.localizedDescription }
            await refresh()
        }
    }
    func importURL(_ url: URL, category: String? = nil) {
        run { workspace in
            let data = try await Task.detached(priority: .userInitiated) {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let limit = category == nil ? PlistValue.maximumBytes : 64 * 1024 * 1024
                let file = try FileHandle(forReadingFrom: url)
                defer { try? file.close() }
                let bytes = try file.read(upToCount: limit + 1) ?? Data()
                guard bytes.count <= limit else { throw ElyraError.invalid("File exceeds the import size limit.") }
                return bytes
            }.value
            if let category { _ = try await workspace.importAsset(data: data, name: url.lastPathComponent, category: category) }
            else { _ = try await workspace.importDocument(data: data, name: url.lastPathComponent) }
        }
    }
}
struct FieldSearchResult: Identifiable, Sendable {
    let document: UUID
    let name: String
    let key: String
    let path: [String]
    var id: String { document.uuidString + ":" + path.map { "\($0.utf8.count):\($0)" }.joined() }
}
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.propertyList, .json, .plainText, .data] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

extension AppEnvironment {
    func beginRespring() -> Bool {
        guard busy == 0, !respringing, !systemRecoveryPending, !RuntimeDeviceContext.current.simulator else { error = "Finish pending operations and system recovery before restarting the interface."; return false }
        respringing = true; return true
    }
    func connectDevice() {
        performDevice { store in
            self.deviceSnapshot = try await store.connect()
        }
    }
    func performDevice(_ action: @escaping @MainActor (SystemConfigurationStore) async throws -> Void) {
        guard busy == 0, !respringing else { return }
        busy += 1
        Task {
            defer { busy -= 1 }
            do {
                if deviceStore == nil {
                    guard let workspace else { throw ElyraError.systemUnavailable }
                    deviceStore = try SystemConfigurationStore(root: workspace.root.appendingPathComponent("SystemBackups"), binding: DeviceBackend.binding(), access: DeviceBackend.access())
                }
                if let store = deviceStore {
                    try await action(store)
                    deviceBackups = await store.listing()
                    systemRecoveryPending = await store.recoveryPending()
                }
                systemError = nil
            } catch {
                systemError = error.localizedDescription; self.error = error.localizedDescription
                deviceSnapshot = nil; deviceLinks.removeAll()
                if let deviceStore {
                    deviceBackups = await deviceStore.listing()
                    systemRecoveryPending = await deviceStore.recoveryPending()
                }
            }
        }
    }
    func openDeviceEditor(_ completion: @escaping @MainActor (UUID) -> Void) {
        guard let deviceSnapshot, let workspace else { return }
        run { workspace in
            let document = try await workspace.importDocument(data: deviceSnapshot.data, name: "MobileGestalt.plist")
            self.deviceLinks[document.record.id] = deviceSnapshot
            completion(document.record.id)
        }
    }
    func saveToDevice(documentID: UUID, value: PlistValue, expected: DocumentSnapshot, completion: @escaping @MainActor (DocumentSnapshot) -> Void) {
        guard let source = deviceLinks[documentID] else { error = "Read the device configuration again before writing."; return }
        performDevice { store in
            let saved = try await store.apply(value, expected: source)
            self.deviceSnapshot = saved; self.deviceLinks[documentID] = saved
            guard let workspace = self.workspace else { return }
            do { let copy = try await workspace.commit(saved.value, expected: expected, reason: "System write verified"); completion(copy) }
            catch {
                self.deviceLinks.removeValue(forKey: documentID)
                self.error = "The system write was verified, but the local working copy could not be updated. Reconnect before editing again."
            }
            await self.refresh()
        }
    }
}
