// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public struct DocumentRecord: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let date: Date
    public let filename: String
}
public struct DocumentSnapshot: Sendable {
    public let record: DocumentRecord
    public let data: Data
    public let value: PlistValue
    public var revision: String { Digest.sha256(data) }
}
public struct BackupRecord: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let documentID: UUID
    public let name: String
    public let date: Date
    public let reason: String
    public let digest: String
    public let byteCount: Int
    public var filename: String { id.uuidString + ".plist" }
}
public struct OperationRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let operation: String
    public let detail: String
}
public struct AssetRecord: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let filename: String
    public let category: String
    public let date: Date
    public let byteCount: Int
    public let digest: String
}
public struct WorkspaceState: Codable, Sendable {
    public var schemaVersion = 3
    public var documents: [DocumentRecord] = []
    public var backups: [BackupRecord] = []
    public var assets: [AssetRecord] = []
    public var trash: [AssetRecord] = []
    public var history: [OperationRecord] = []
    public var favorites: Set<String> = []
    public var islandObservations: [IslandObservation] = []
    public var assetBackups: [AssetBackupRecord] = []
    public init() {}
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, documents, backups, assets, trash, history, favorites, islandObservations, assetBackups
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let version = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard (1...3).contains(version) else { throw ElyraError.invalid("This workspace was created by a newer Elyra version.") }
        documents = try c.decode([DocumentRecord].self, forKey: .documents)
        backups = try c.decode([BackupRecord].self, forKey: .backups)
        assets = try c.decode([AssetRecord].self, forKey: .assets)
        trash = try c.decode([AssetRecord].self, forKey: .trash)
        history = try c.decode([OperationRecord].self, forKey: .history)
        favorites = try c.decode(Set<String>.self, forKey: .favorites)
        islandObservations = try c.decodeIfPresent([IslandObservation].self, forKey: .islandObservations) ?? []
        assetBackups = try c.decodeIfPresent([AssetBackupRecord].self, forKey: .assetBackups) ?? []
    }
}

private struct CommitJournal: Codable {
    let document: DocumentRecord
    let expected: String
    let desired: String
    let previousState: WorkspaceState?
    let state: WorkspaceState
}

/// One actor per application, shared by every window. All targets are managed copies.
public actor Workspace {
    public let root: URL
    private var state: WorkspaceState
    private let fm = FileManager.default
    public init(root: URL) throws {
        self.root = root.standardizedFileURL
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        for name in ["Documents", "Backups", "Assets", "AssetBackups", "Drafts"] {
            try fm.createDirectory(at: root.appendingPathComponent(name), withIntermediateDirectories: true)
        }
        let index = root.appendingPathComponent("index.json")
        state = fm.fileExists(atPath: index.path) ? try JSONDecoder().decode(WorkspaceState.self, from: Data(contentsOf: index)) : WorkspaceState()
        let journalURL = root.appendingPathComponent("commit.json")
        if fm.fileExists(atPath: journalURL.path) {
            let journal = try JSONDecoder().decode(CommitJournal.self, from: Data(contentsOf: journalURL))
            guard journal.document.filename == journal.document.id.uuidString + ".plist" else { throw ElyraError.integrity }
            let bytes = try Data(contentsOf: root.appendingPathComponent("Documents").appendingPathComponent(journal.document.filename))
            let digest = Digest.sha256(bytes)
            if digest == journal.desired {
                state = journal.state
                try JSONEncoder().encode(state).write(to: index, options: .atomic)
            } else if digest == journal.expected {
                if let previous = journal.previousState { state = previous; try JSONEncoder().encode(state).write(to: index, options: .atomic) }
            } else { throw ElyraError.integrity }
            try fm.removeItem(at: journalURL)
        }
        let assetJournalURL = root.appendingPathComponent("asset-commit.json")
        if fm.fileExists(atPath: assetJournalURL.path) {
            let journal = try JSONDecoder().decode(AssetCommitJournal.self, from: Data(contentsOf: assetJournalURL))
            guard journal.asset.filename == URL(fileURLWithPath: journal.asset.filename).lastPathComponent,
                  journal.asset.filename.hasPrefix(journal.asset.id.uuidString),
                  journal.asset.byteCount <= 64 * 1024 * 1024 else { throw ElyraError.integrity }
            let target = root.appendingPathComponent("Assets").appendingPathComponent(journal.asset.filename)
            guard target.resolvingSymlinksInPath().path.hasPrefix(root.resolvingSymlinksInPath().path + "/") else { throw ElyraError.outsideWorkspace }
            let digest = Digest.sha256(try Data(contentsOf: target))
            if digest == journal.desired { state = journal.state }
            else if digest == journal.asset.digest { state = journal.previousState }
            else { throw ElyraError.integrity }
            try JSONEncoder().encode(state).write(to: index, options: .atomic)
            try fm.removeItem(at: assetJournalURL)
        }
    }
    public func listing() -> WorkspaceState { state }
    private func url(_ directory: String, _ filename: String) throws -> URL {
        guard filename == URL(fileURLWithPath: filename).lastPathComponent,
              !filename.isEmpty, filename != ".", filename != ".." else { throw ElyraError.outsideWorkspace }
        let result = root.appendingPathComponent(directory).appendingPathComponent(filename)
        guard result.resolvingSymlinksInPath().path.hasPrefix(root.resolvingSymlinksInPath().path + "/") else { throw ElyraError.outsideWorkspace }
        return result
    }
    private func requireWritableState() throws {
        guard !fm.fileExists(atPath: root.appendingPathComponent("commit.json").path),
              !fm.fileExists(atPath: root.appendingPathComponent("asset-commit.json").path) else {
            throw ElyraError.invalid("An interrupted transaction requires workspace recovery. Reopen Elyra before saving.")
        }
    }
    private func persist(_ next: WorkspaceState) throws {
        try JSONEncoder().encode(next).write(to: root.appendingPathComponent("index.json"), options: .atomic)
        state = next
    }
    private func event(_ operation: String, _ detail: String, in state: inout WorkspaceState) {
        state.history.insert(OperationRecord(id: UUID(), date: Date(), operation: operation, detail: detail), at: 0)
        if state.history.count > 500 { state.history.removeLast(state.history.count - 500) }
    }
    public func importDocument(data: Data, name: String) throws -> DocumentSnapshot {
        try requireWritableState()
        let value = try PlistValue.decode(data)
        let id = UUID()
        let record = DocumentRecord(id: id, name: String(name.prefix(240)), date: Date(), filename: id.uuidString + ".plist")
        let target = try url("Documents", record.filename)
        try data.write(to: target, options: .atomic)
        guard try Data(contentsOf: target) == data else { throw ElyraError.integrity }
        // This is an imported-file baseline, never a claim about factory device configuration.
        _ = try createBackup(data, document: record, reason: "Imported baseline")
        var next = state; next.documents.insert(record, at: 0)
        event("Import", record.name, in: &next); try persist(next)
        return DocumentSnapshot(record: record, data: data, value: value)
    }
    public func snapshot(_ id: UUID) throws -> DocumentSnapshot {
        guard let record = state.documents.first(where: { $0.id == id }) else { throw ElyraError.invalid("Document not found.") }
        let data = try Data(contentsOf: url("Documents", record.filename))
        return DocumentSnapshot(record: record, data: data, value: try PlistValue.decode(data))
    }
    private func createBackup(_ data: Data, document: DocumentRecord, reason: String) throws -> BackupRecord {
        try requireWritableState()
        let backup = BackupRecord(id: UUID(), documentID: document.id, name: document.name, date: Date(), reason: reason, digest: Digest.sha256(data), byteCount: data.count)
        let target = try url("Backups", backup.filename)
        try data.write(to: target, options: .atomic)
        guard try Data(contentsOf: target) == data else { throw ElyraError.integrity }
        var next = state; next.backups.insert(backup, at: 0)
        event("Backup", reason + ": " + document.name, in: &next); try persist(next)
        return backup
    }
    @discardableResult public func backup(_ id: UUID) throws -> BackupRecord {
        let current = try snapshot(id)
        return try createBackup(current.data, document: current.record, reason: "Manual backup")
    }
    public func backupData(_ id: UUID) throws -> Data {
        guard let record = state.backups.first(where: { $0.id == id }) else { throw ElyraError.invalid("Backup not found.") }
        let data = try Data(contentsOf: url("Backups", record.filename))
        guard data.count == record.byteCount, Digest.sha256(data) == record.digest else { throw ElyraError.integrity }
        _ = try PlistValue.decode(data)
        return data
    }
    public func commit(_ edited: PlistValue, expected: DocumentSnapshot, reason: String = "Save local document") throws -> DocumentSnapshot {
        let output = try edited.encoded()
        guard output.count <= PlistValue.maximumBytes else { throw ElyraError.invalid("Choose a plist smaller than 16 MB.") }
        return try commitBytes(output, expected: expected, reason: reason)
    }
    private func commitBytes(_ output: Data, expected: DocumentSnapshot, reason: String) throws -> DocumentSnapshot {
        try requireWritableState()
        let current = try snapshot(expected.record.id)
        guard current.revision == expected.revision else { throw ElyraError.conflict }
        let decoded = try PlistValue.decode(output)
        if current.data == output { return current }
        _ = try createBackup(current.data, document: current.record, reason: "Before " + reason)
        let previousState = state
        var next = state
        event(reason, current.record.name + " • local copy • readback verified", in: &next)
        let journalURL = root.appendingPathComponent("commit.json")
        let journal = CommitJournal(document: current.record, expected: current.revision, desired: Digest.sha256(output), previousState: previousState, state: next)
        try JSONEncoder().encode(journal).write(to: journalURL, options: .atomic)
        let target = try url("Documents", current.record.filename)
        do {
            try output.write(to: target, options: .atomic)
            guard try Data(contentsOf: target) == output else { throw ElyraError.integrity }
            try persist(next)
            try fm.removeItem(at: journalURL)
        } catch {
            // Preserve the actual failure. A rollback is successful only after exact readback.
            do {
                try current.data.write(to: target, options: .atomic)
                guard try Data(contentsOf: target) == current.data else { throw ElyraError.integrity }
                var recovered = previousState
                event("Save failed; previous bytes restored", current.record.name, in: &recovered)
                try persist(recovered)
                try fm.removeItem(at: journalURL)
            } catch { throw ElyraError.invalid("Write and recovery failed. Keep the backup and commit journal; reopen the workspace before further edits.") }
            throw error
        }
        return DocumentSnapshot(record: current.record, data: output, value: decoded)
    }
    public func restore(_ backupID: UUID, expected: DocumentSnapshot) throws -> DocumentSnapshot {
        guard let record = state.backups.first(where: { $0.id == backupID }), record.documentID == expected.record.id else { throw ElyraError.invalid("This backup belongs to a different local document.") }
        return try commitBytes(backupData(backupID), expected: expected, reason: "Restore local document")
    }
    public func toggleFavorite(_ id: String) throws {
        try requireWritableState()
        var next = state
        if next.favorites.contains(id) { next.favorites.remove(id) } else { next.favorites.insert(id) }
        try persist(next)
    }
    public func importAsset(data: Data, name: String, category: String) throws -> AssetRecord {
        try requireWritableState()
        guard !data.isEmpty, data.count <= 64 * 1024 * 1024 else { throw ElyraError.invalid("Choose a nonempty asset smaller than 64 MB.") }
        let id = UUID()
        let ext = URL(fileURLWithPath: name).pathExtension.lowercased().filter { $0.isASCII && $0.isLetter || $0.isNumber }
        let filename = id.uuidString + (ext.isEmpty ? "" : "." + String(ext.prefix(12)))
        let asset = AssetRecord(id: id, name: String(name.prefix(240)), filename: filename, category: category, date: Date(), byteCount: data.count, digest: Digest.sha256(data))
        let target = try url("Assets", filename)
        try data.write(to: target, options: .atomic)
        guard try Data(contentsOf: target) == data else { throw ElyraError.integrity }
        var next = state; next.assets.insert(asset, at: 0)
        event("Import asset", asset.name, in: &next); try persist(next)
        return asset
    }
    public func assetURL(_ id: UUID) throws -> URL {
        guard let asset = state.assets.first(where: { $0.id == id }) else { throw ElyraError.invalid("Asset not found.") }
        let target = try url("Assets", asset.filename)
        let data = try Data(contentsOf: target)
        guard data.count == asset.byteCount, Digest.sha256(data) == asset.digest else { throw ElyraError.integrity }
        return target
    }
    public func deleteAsset(_ id: UUID) throws {
        try requireWritableState()
        guard let asset = state.assets.first(where: { $0.id == id }) else { return }
        // Move into recoverable trash rather than silently destroying the only copy.
        let target = try assetURL(id)
        try fm.createDirectory(at: root.appendingPathComponent("Trash"), withIntermediateDirectories: true)
        try fm.moveItem(at: target, to: url("Trash", asset.filename))
        var next = state; next.assets.removeAll { $0.id == id }; next.trash.insert(asset, at: 0)
        event("Move asset to Trash", asset.name, in: &next)
        do { try persist(next) } catch {
            try fm.moveItem(at: url("Trash", asset.filename), to: target); throw error
        }
    }
    public func restoreAsset(_ id: UUID) throws {
        try requireWritableState()
        guard let asset = state.trash.first(where: { $0.id == id }) else { throw ElyraError.invalid("Asset not found.") }
        let source = try url("Trash", asset.filename)
        let bytes = try Data(contentsOf: source)
        guard Digest.sha256(bytes) == asset.digest, bytes.count == asset.byteCount else { throw ElyraError.integrity }
        let target = try url("Assets", asset.filename)
        try fm.moveItem(at: source, to: target)
        var next = state; next.trash.removeAll { $0.id == id }; next.assets.insert(asset, at: 0)
        event("Restore asset", asset.name, in: &next)
        do { try persist(next) } catch { try fm.moveItem(at: target, to: source); throw error }
    }
    public func assetData(_ id: UUID) throws -> Data { try Data(contentsOf: assetURL(id)) }
    public func textSnapshot(_ id: UUID) throws -> TextAssetSnapshot {
        guard let record = state.assets.first(where: { $0.id == id }) else { throw ElyraError.invalid("Asset not found.") }
        return try TextAssetSnapshot(asset: record, data: assetData(id))
    }
    public func saveText(_ text: String, expected: TextAssetSnapshot) throws -> TextAssetSnapshot {
        let output = try expected.encoded(text)
        let record = try commitAsset(output, expected: expected.asset, reason: "Save text file")
        return try TextAssetSnapshot(asset: record, data: output)
    }
    private func commitAsset(_ output: Data, expected: AssetRecord, reason: String) throws -> AssetRecord {
        try requireWritableState()
        guard let current = state.assets.first(where: { $0.id == expected.id }), current == expected else { throw ElyraError.conflict }
        guard output.count <= 64 * 1024 * 1024 else { throw ElyraError.invalid("Choose a nonempty asset smaller than 64 MB.") }
        let target = try assetURL(current.id)
        let bytes = try Data(contentsOf: target)
        if bytes == output { return current }
        let backup = AssetBackupRecord(id: UUID(), assetID: current.id, name: current.name, date: Date(), reason: "Before " + reason, digest: current.digest, byteCount: bytes.count)
        let backupURL = try url("AssetBackups", backup.filename)
        try bytes.write(to: backupURL, options: .atomic)
        guard try Data(contentsOf: backupURL) == bytes else { throw ElyraError.integrity }
        var previous = state; previous.assetBackups.insert(backup, at: 0)
        try persist(previous)
        let updated = AssetRecord(id: current.id, name: current.name, filename: current.filename, category: current.category, date: current.date, byteCount: output.count, digest: Digest.sha256(output))
        var next = previous
        next.assets = next.assets.map { $0.id == updated.id ? updated : $0 }
        event(reason, current.name + " • local copy • readback verified", in: &next)
        let journalURL = root.appendingPathComponent("asset-commit.json")
        try JSONEncoder().encode(AssetCommitJournal(asset: current, desired: updated.digest, previousState: previous, state: next)).write(to: journalURL, options: .atomic)
        do {
            try output.write(to: target, options: .atomic)
            guard try Data(contentsOf: target) == output else { throw ElyraError.integrity }
            try persist(next)
            try fm.removeItem(at: journalURL)
        } catch {
            do {
                try bytes.write(to: target, options: .atomic)
                guard try Data(contentsOf: target) == bytes else { throw ElyraError.integrity }
                var recovered = previous
                event("Save failed; previous bytes restored", current.name, in: &recovered)
                try persist(recovered)
                try fm.removeItem(at: journalURL)
            } catch { throw ElyraError.invalid("Write and recovery failed. Keep the backup and commit journal; reopen the workspace before further edits.") }
            throw error
        }
        return updated
    }
    public func assetBackupData(_ id: UUID) throws -> Data {
        guard let record = state.assetBackups.first(where: { $0.id == id }) else { throw ElyraError.invalid("Backup not found.") }
        let data = try Data(contentsOf: url("AssetBackups", record.filename))
        guard data.count == record.byteCount, Digest.sha256(data) == record.digest else { throw ElyraError.integrity }
        return data
    }
    public func restoreAssetBackup(_ id: UUID, expected: AssetRecord) throws -> AssetRecord {
        guard let backup = state.assetBackups.first(where: { $0.id == id }), backup.assetID == expected.id else {
            throw ElyraError.invalid("This backup belongs to a different local file.")
        }
        return try commitAsset(assetBackupData(id), expected: expected, reason: "Restore local file")
    }
    public func exportOperationHistory() throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(state.history)
    }
    public func islandPlan(documentID: UUID, action: IslandAction) throws -> IslandPlan {
        let current = try snapshot(documentID)
        switch action {
        case .enableFlag:
            return IslandPlan(action: action, snapshot: current, target: try DynamicIslandEngine.enablingFlag(in: current.value), baseline: nil)
        case .restoreBaseline:
            guard let baseline = state.backups.filter({ $0.documentID == documentID && $0.reason == "Imported baseline" }).min(by: { $0.date < $1.date }) else {
                throw ElyraError.invalid("No recorded imported baseline exists. Original values will not be guessed.")
            }
            let original = try PlistValue.decode(backupData(baseline.id))
            let target = try DynamicIslandEngine.restoringRecordedFields(in: current.value, baseline: original)
            return IslandPlan(action: action, snapshot: current, target: target, baseline: baseline)
        }
    }
    public func recordIslandObservation(_ observation: IslandObservation) throws {
        try requireWritableState()
        guard observation.notes.utf8.count <= 16_000, !observation.hardware.isEmpty,
              !observation.osVersion.isEmpty, !observation.build.isEmpty else {
            throw ElyraError.invalid("Complete device details and keep observation notes under 16 KB.")
        }
        if let id = observation.documentID {
            let current = try snapshot(id)
            guard current.revision == observation.documentRevision else { throw ElyraError.conflict }
        } else if observation.documentRevision != nil { throw ElyraError.invalid("Observation revision has no matching document.") }
        var next = state
        next.islandObservations.insert(observation, at: 0)
        event("Record DI observation", observation.activity.rawValue + " • " + (observation.simulator ? "simulator; no system proof" : "user-reported physical device; not verified by Elyra"), in: &next)
        try persist(next)
    }
    public func exportResearchReport() throws -> Data {
        struct Report: Encodable {
            let schemaVersion: Int
            let generatedAt: Date
            let scope: String
            let observations: [IslandObservation]
        }
        let report = Report(schemaVersion: 2, generatedAt: Date(),
                            scope: "User-recorded observations, not automated proof of system modification. Simulator records are never physical-device evidence.",
                            observations: state.islandObservations)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(report)
    }
    public func draftURL(window: UUID, document: UUID) -> URL {
        root.appendingPathComponent("Drafts").appendingPathComponent(window.uuidString + "-" + document.uuidString + ".json")
    }
    public func saveDraft(_ draft: LocalDraft, window: UUID, document: UUID) throws {
        try draft.value.validate()
        try JSONEncoder().encode(draft).write(to: draftURL(window: window, document: document), options: .atomic)
    }
    public func loadDraft(window: UUID, document: UUID) throws -> LocalDraft? {
        let target = draftURL(window: window, document: document)
        guard fm.fileExists(atPath: target.path) else { return nil }
        return try JSONDecoder().decode(LocalDraft.self, from: Data(contentsOf: target))
    }
    public func discardDraft(window: UUID, document: UUID) throws {
        let target = draftURL(window: window, document: document)
        if fm.fileExists(atPath: target.path) { try fm.removeItem(at: target) }
    }
    public func requireSystemWriter() throws { throw ElyraError.systemUnavailable }
}
public struct LocalDraft: Codable, Sendable {
    public let revision: String
    public let value: PlistValue
    public init(revision: String, value: PlistValue) { self.revision = revision; self.value = value }
}
