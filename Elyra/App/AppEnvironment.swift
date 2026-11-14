// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

@MainActor final class AppEnvironment: ObservableObject {
    let workspace: Workspace?
    @Published var state = WorkspaceState()
    @Published var error: String?
    @Published var busy = 0
    @Published var fieldIndex: [FieldSearchResult] = []
    init() {
        do {
            let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            workspace = try Workspace(root: base.appendingPathComponent("Elyra", isDirectory: true))
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
        guard let workspace else { error = L("Workspace could not be opened. Export existing files before attempting recovery."); return }
        busy += 1
        Task {
            defer { busy -= 1 }
            do { try await action(workspace) } catch { self.error = L(error.localizedDescription) }
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
    static var readableContentTypes: [UTType] { [.propertyList, .data] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }
