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
    @Published var connectingDevice = false
    @Published var deviceAccessChecked = false
    @Published var systemRecoveryPending = false
    var deviceStore: SystemConfigurationStore?
    var deviceLinks: [UUID: SystemSnapshot] = [:]
    @Published var fieldIndex: [FieldSearchResult] = []
    @Published var configurationPlans: [ConfigurationPlan] = []
    private var fieldCache: [UUID: (String, Int, [FieldSearchResult])] = [:]
    private var refreshTask: Task<Void, Never>?
    private var refreshRequested = false
    private var workingDocumentID: UUID?
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
        refreshRequested = true
        if let task = refreshTask { await task.value; return }
        let task = Task {
            repeat { refreshRequested = false; await refreshContents() } while refreshRequested
            refreshTask = nil
        }
        refreshTask = task
        await task.value
    }
    private func refreshContents() async {
        guard let workspace else { return }
        state = await workspace.listing()
        do { configurationPlans = try await workspace.configurationPlans() } catch { self.error = error.localizedDescription }
        var nextCache: [UUID: (String, Int, [FieldSearchResult])] = [:]
        var fields: [FieldSearchResult] = []
        for record in state.documents {
            do {
                let snapshot = try await workspace.snapshot(record.id)
                let remaining = max(0, 100_000 - fields.count)
                if let cached = fieldCache[record.id], cached.0 == snapshot.revision, cached.1 >= remaining || cached.2.count < cached.1 {
                    let visible = Array(cached.2.prefix(remaining)); fields += visible
                    nextCache[record.id] = (snapshot.revision, remaining, visible); continue
                }
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
                nextCache[record.id] = (snapshot.revision, remaining, indexed)
                fields += indexed
            } catch { self.error = error.localizedDescription }
        }
        fieldCache = nextCache; fieldIndex = fields
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
    var deviceAccessState: DeviceAccessState {
        DeviceAccessState.resolve(simulator: RuntimeDeviceContext.current.simulator, checking: connectingDevice,
            readable: deviceSnapshot != nil, writable: deviceSnapshot?.writable == true,
            failed: systemError != nil, recovery: systemRecoveryPending)
    }
    func ensureDeviceConnection() async {
        guard !deviceAccessChecked, !connectingDevice, !RuntimeDeviceContext.current.simulator else { return }
        if let task = startDeviceConnection(showErrorAlert: false) { await task.value }
    }
    func connectDevice() { _ = startDeviceConnection(showErrorAlert: true) }
    private func startDeviceConnection(showErrorAlert: Bool) -> Task<Void, Never>? {
        guard !connectingDevice, busy == 0, !respringing, !RuntimeDeviceContext.current.simulator else { return nil }
        connectingDevice = true; deviceAccessChecked = true
        return performDevice(showErrorAlert: showErrorAlert) { store in
            defer { self.connectingDevice = false }
            self.deviceSnapshot = try await store.connect()
        }
    }
    private func requireSystemStore() throws -> SystemConfigurationStore {
        if let deviceStore { return deviceStore }
        guard let workspace else { throw ElyraError.systemUnavailable }
        let store = try SystemConfigurationStore(root: workspace.root.appendingPathComponent("SystemBackups"), binding: DeviceBackend.binding(), access: DeviceBackend.access())
        deviceStore = store; return store
    }
    func inspectDeviceBackup(_ id: UUID) async throws -> SystemBackupInspection { try await requireSystemStore().inspectedBackup(id) }
    @discardableResult
    func performDevice(showErrorAlert: Bool = true, invalidateOnFailure: Bool = true, _ action: @escaping @MainActor (SystemConfigurationStore) async throws -> Void) -> Task<Void, Never>? {
        guard busy == 0, !respringing else { return nil }
        busy += 1
        return Task {
            defer { busy -= 1; connectingDevice = false }
            do {
                let store = try requireSystemStore()
                try await action(store)
                deviceBackups = await store.listing()
                systemRecoveryPending = await store.recoveryPending()
                systemError = nil
            } catch {
                if showErrorAlert { self.error = error.localizedDescription }
                if invalidateOnFailure {
                    systemError = error.localizedDescription
                    deviceSnapshot = nil; deviceLinks.removeAll()
                }
                if let deviceStore {
                    deviceBackups = await deviceStore.listing()
                    systemRecoveryPending = await deviceStore.recoveryPending()
                }
            }
        }
    }
    func openDeviceEditor(_ completion: @escaping @MainActor (UUID) -> Void) {
        guard let deviceSnapshot, workspace != nil else { return }
        run { workspace in
            if let id = self.workingDocumentID, let copy = try? await workspace.snapshot(id), copy.value == deviceSnapshot.value {
                self.deviceLinks[id] = deviceSnapshot; completion(id); return
            }
            let document = try await workspace.importDocument(data: deviceSnapshot.data, name: "MobileGestalt.plist")
            self.workingDocumentID = document.record.id
            self.deviceLinks[document.record.id] = deviceSnapshot
            completion(document.record.id)
        }
    }
    func reconnectEditor(_ expected: DocumentSnapshot, draft: PlistValue, window: UUID?, completion: @escaping @MainActor (DocumentSnapshot, PlistValue) -> Void) {
        performDevice(invalidateOnFailure: false) { store in
            let live = try await store.connect(); self.deviceSnapshot = live; self.deviceAccessChecked = true
            guard let workspace = self.workspace else { throw ElyraError.systemUnavailable }
            let current = try await workspace.snapshot(expected.record.id)
            guard current.revision == expected.revision else { throw ElyraError.conflict }
            let merged = try DraftRebase.merge(base: expected.value, draft: draft, current: live.value)
            let base = try await workspace.commit(live.value, expected: current, reason: "Refresh device working copy")
            if let window { try await workspace.saveDraft(LocalDraft(revision: base.revision, value: merged), window: window, document: base.record.id) }
            self.workingDocumentID = base.record.id; self.deviceLinks[base.record.id] = live
            completion(base, merged); await self.refresh()
        }
    }
    func loadDeviceBackups() { performDevice(invalidateOnFailure: false) { _ in } }
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
