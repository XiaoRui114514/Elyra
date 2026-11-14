// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore

final class TextAssetTests: XCTestCase, @unchecked Sendable {
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    override func tearDown() { try? FileManager.default.removeItem(at: root) }
    func testTextSaveCreatesVerifiedBackupAndRestoresExactBOMBytes() async throws {
        let w = try Workspace(root: root)
        let original = Data([0xef,0xbb,0xbf]) + Data("Original\r\n中文".utf8)
        let asset = try await w.importAsset(data: original, name: "Notes.txt", category: "Files")
        let snapshot = try await w.textSnapshot(asset.id)
        let saved = try await w.saveText("Edited\n中文", expected: snapshot)
        XCTAssertTrue(saved.data.starts(with: [0xef,0xbb,0xbf]))
        let state = await w.listing()
        XCTAssertEqual(state.assetBackups.count, 1)
        let backup = try await w.assetBackupData(state.assetBackups[0].id)
        XCTAssertEqual(backup, original)
        let restored = try await w.restoreAssetBackup(state.assetBackups[0].id, expected: saved.asset)
        let bytes = try await w.assetData(restored.id)
        XCTAssertEqual(bytes, original)
    }
    func testTextNoOpDoesNotReencodeOrCreateBackup() async throws {
        let w = try Workspace(root: root)
        let bytes = Data([0xef,0xbb,0xbf]) + Data("A\r\nB".utf8)
        let asset = try await w.importAsset(data: bytes, name: "A.txt", category: "Files")
        let snapshot = try await w.textSnapshot(asset.id)
        let saved = try await w.saveText(snapshot.text, expected: snapshot)
        XCTAssertEqual(saved.data, bytes)
        let state = await w.listing()
        XCTAssertTrue(state.assetBackups.isEmpty)
    }
    func testStaleWindowTextSaveIsRejected() async throws {
        let w = try Workspace(root: root)
        let asset = try await w.importAsset(data: Data("original".utf8), name: "A.txt", category: "Files")
        let snapshot = try await w.textSnapshot(asset.id)
        _ = try await w.saveText("first", expected: snapshot)
        do { _ = try await w.saveText("second", expected: snapshot); XCTFail("Stale text overwrite allowed") }
        catch { XCTAssertEqual(error as? ElyraError, .conflict) }
    }
    func testBinaryOversizedAndInvalidUTF8TextRejected() async throws {
        let w = try Workspace(root: root)
        for bytes in [Data([0xff,0xfe]), Data([65,0,66]), Data(repeating: 65, count: TextAssetSnapshot.maximumBytes+1)] {
            let asset = try await w.importAsset(data: bytes, name: "Binary.txt", category: "Files")
            do { _ = try await w.textSnapshot(asset.id); XCTFail("Invalid text opened") } catch { }
        }
    }
    func testTextCanBeClearedAndRestored() async throws {
        let w = try Workspace(root: root)
        let asset = try await w.importAsset(data: Data("clear me".utf8), name: "A.txt", category: "Files")
        let snapshot = try await w.textSnapshot(asset.id)
        let empty = try await w.saveText("", expected: snapshot)
        XCTAssertTrue(empty.data.isEmpty)
        let state = await w.listing()
        let restored = try await w.restoreAssetBackup(state.assetBackups[0].id, expected: empty.asset)
        let actual = try await w.assetData(restored.id)
        XCTAssertEqual(actual, Data("clear me".utf8))
    }
    func testCorruptAssetBackupAndCrossFileRestoreRejected() async throws {
        let w = try Workspace(root: root)
        let a = try await w.importAsset(data: Data("a".utf8), name: "A.txt", category: "Files")
        let b = try await w.importAsset(data: Data("b".utf8), name: "B.txt", category: "Files")
        let snapshot = try await w.textSnapshot(a.id)
        _ = try await w.saveText("edited", expected: snapshot)
        let state = await w.listing(); let backup = state.assetBackups[0]
        do { _ = try await w.restoreAssetBackup(backup.id, expected: b); XCTFail("Cross-file restore allowed") } catch { }
        try Data("x".utf8).write(to: root.appendingPathComponent("AssetBackups/" + backup.filename))
        do { _ = try await w.assetBackupData(backup.id); XCTFail("Corrupt backup accepted") }
        catch { XCTAssertEqual(error as? ElyraError, .integrity) }
    }
    func testAssetCommitJournalRecoversMatchingPayloadAndMetadata() async throws {
        let w = try Workspace(root: root)
        let a = try await w.importAsset(data: Data("old".utf8), name: "A.txt", category: "Files")
        let before = await w.listing()
        let output = Data("new value".utf8)
        let updated = AssetRecord(id: a.id, name: a.name, filename: a.filename, category: a.category, date: a.date, byteCount: output.count, digest: Digest.sha256(output))
        var after = before; after.assets = [updated]
        let journal = AssetCommitJournal(asset: a, desired: updated.digest, previousState: before, state: after)
        try JSONEncoder().encode(journal).write(to: root.appendingPathComponent("asset-commit.json"))
        try output.write(to: root.appendingPathComponent("Assets/" + a.filename))
        let reopened = try Workspace(root: root)
        let read = try await reopened.textSnapshot(a.id)
        XCTAssertEqual(read.asset.digest, updated.digest)
        XCTAssertEqual(read.text, "new value")
    }
    func testAssetRollbackRecoveryRestoresPreviousMetadata() async throws {
        let w = try Workspace(root: root)
        let a = try await w.importAsset(data: Data("old".utf8), name: "A.txt", category: "Files")
        let before = await w.listing()
        let changed = AssetRecord(id: a.id, name: a.name, filename: a.filename, category: a.category, date: a.date, byteCount: 7, digest: "uncommitted")
        var after = before; after.assets = [changed]
        try JSONEncoder().encode(after).write(to: root.appendingPathComponent("index.json"))
        let journal = AssetCommitJournal(asset: a, desired: changed.digest, previousState: before, state: after)
        try JSONEncoder().encode(journal).write(to: root.appendingPathComponent("asset-commit.json"))
        let reopened = try Workspace(root: root)
        let read = try await reopened.textSnapshot(a.id)
        XCTAssertEqual(read.asset.digest, a.digest)
        XCTAssertEqual(read.text, "old")
    }
}
