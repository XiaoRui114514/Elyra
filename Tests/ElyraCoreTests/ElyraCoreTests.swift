// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore

final class PlistTests: XCTestCase {
    func testAllTypesRoundTripWithoutCoercion() throws {
        let value: PlistValue = .dictionary([
            "s": .string("Elyra 中文"), "i": .integer(9_007_199_254_740_993), "r": .real(1.25),
            "b": .boolean(true), "d": .data(Data([0, 255])), "date": .date(Date(timeIntervalSince1970: 100)),
            "a": .array([.integer(0), .dictionary(["nested": .boolean(false)])])
        ])
        XCTAssertEqual(try PlistValue.decode(value.encoded()), value)
        XCTAssertEqual(try PlistValue.parseXML(value.xml), value)
    }
    func testBoolIntegerAndRealDiffer() {
        XCTAssertNotEqual(PlistValue.boolean(true), .integer(1))
        XCTAssertNotEqual(PlistValue.integer(1), .real(1))
        XCTAssertEqual(PlistChange.between(.boolean(true), .integer(1)).count, 1)
    }
    func testMalformedAndOversizedPlistsAreRejected() {
        XCTAssertThrowsError(try PlistValue.decode(Data("not a plist".utf8)))
        XCTAssertThrowsError(try PlistValue.decode(Data(repeating: 0, count: PlistValue.maximumBytes + 1)))
        XCTAssertThrowsError(try PlistValue.decode(Data()))
    }
    func testNonFiniteValuesAndDeepNestingRejected() {
        XCTAssertThrowsError(try PlistValue.real(.infinity).encoded())
        XCTAssertThrowsError(try PlistValue.date(Date(timeIntervalSince1970: .nan)).encoded())
        var nested = PlistValue.string("end")
        for _ in 0..<70 { nested = .array([nested]) }
        XCTAssertThrowsError(try nested.encoded())
    }
    func testNestedEditingAndAbsentOriginal() throws {
        var value: PlistValue = .dictionary(["CacheExtra": .dictionary(["a/b": .array([.integer(2)])])])
        let original = value
        try value.set(.boolean(true), at: ["CacheExtra", "new"])
        XCTAssertEqual(value.value(at: ["CacheExtra", "new"]), .boolean(true))
        try value.set(nil, at: ["CacheExtra", "new"])
        XCTAssertEqual(value, original)
        try value.set(.integer(3), at: ["CacheExtra", "a/b", "0"])
        XCTAssertEqual(value.value(at: ["CacheExtra", "a/b", "0"]), .integer(3))
        XCTAssertThrowsError(try value.set(nil, at: []))
        XCTAssertThrowsError(try value.set(.integer(1), at: ["CacheExtra", "a/b", "999"]))
    }
    func testDifferenceIDsDoNotCollideOnSlashKeys() {
        let a: PlistValue = .dictionary([:])
        let b: PlistValue = .dictionary(["a/b": .integer(1), "a": .dictionary(["b": .integer(2)])])
        let changes = PlistChange.between(a, b)
        XCTAssertEqual(Set(changes.map(\.id)).count, changes.count)
        XCTAssertEqual(changes.first(where: { $0.path == ["a/b"] })?.displayPath, "a~1b")
    }
    func testUntouchedPresetPreservesArtworkMembersAndRoot() throws {
        var value: PlistValue = .dictionary(["CacheData": .data(Data([1,2,3])), "CacheExtra": .dictionary(["oPeik/9e8lQWMszEjbPzng": .dictionary(["ArtworkDeviceSubType": .integer(123), "ArtworkDeviceProductDescription": .string("Original")])])])
        let before = value
        try Capability.all.first { $0.id == "dynamicIsland" }!.stage(in: &value)
        XCTAssertEqual(value.value(at: ["CacheData"]), before.value(at: ["CacheData"]))
        XCTAssertEqual(value.value(at: ["CacheExtra", "oPeik/9e8lQWMszEjbPzng"]), before.value(at: ["CacheExtra", "oPeik/9e8lQWMszEjbPzng"]))
        XCTAssertEqual(PlistChange.between(before, value).count, 1)
    }
    func testDeviceSpecificSiriNotGuessedAndNoCacheExtraRejected() {
        var value: PlistValue = .dictionary(["CacheExtra": .dictionary([:])])
        XCTAssertThrowsError(try Capability.all.first { $0.id == "siriOnDevice" }!.stage(in: &value))
        var invalid: PlistValue = .array([])
        XCTAssertThrowsError(try Capability.all[0].stage(in: &invalid))
    }
    func testSHA256KnownVectors() {
        XCTAssertEqual(Digest.sha256(Data()), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(Digest.sha256(Data("abc".utf8)), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(Digest.sha256(Data(repeating: 97, count: 1_000_000)), "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }
    func testResponsiveThresholdsAndAccessibility() {
        for width in stride(from: 320.0, through: 1600, by: 1) {
            let layout = WindowLayout.resolve(width: width, height: 768)
            XCTAssertEqual(layout, width < 720 ? .compact : width < 1100 ? .medium : .wide)
        }
        XCTAssertEqual(WindowLayout.resolve(width: 1300, height: 300), .compact)
        XCTAssertEqual(WindowLayout.resolve(width: 1300, height: 800, accessibilityText: true), .compact)
    }
    func testNoOSVersionClaimsSystemWriteSupport() {
        for major in [17, 26, 27, 28] {
            let r = CompatibilityEngine.report(version: .init(majorVersion: major, minorVersion: 0, patchVersion: 1))
            XCTAssertEqual(r.ui, .unverified)
            XCTAssertEqual(r.localFiles, .partial)
            XCTAssertEqual(r.systemWrite, .unverified)
            XCTAssertEqual(r.visualEffect, .unverified)
        }
    }
}

// XCTest owns one immutable temporary root per test instance; task mutations go through Workspace.
final class WorkspaceTests: XCTestCase, @unchecked Sendable {
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    override func tearDown() { try? FileManager.default.removeItem(at: root) }
    private var value: PlistValue { .dictionary(["CacheExtra": .dictionary(["test": .integer(1)])]) }
    func testImportCreatesVerifiedBaselineAndReloads() async throws {
        let workspace = try Workspace(root: root)
        let data = try value.encoded()
        let snapshot = try await workspace.importDocument(data: data, name: "Actual.plist")
        let state = await workspace.listing()
        XCTAssertEqual(state.backups.count, 1)
        let backed = try await workspace.backupData(state.backups[0].id)
        XCTAssertEqual(backed, data)
        let reopened = try Workspace(root: root)
        let read = try await reopened.snapshot(snapshot.record.id)
        XCTAssertEqual(read.data, data)
    }
    func testSaveBacksUpAndRestoresExactOriginalBytes() async throws {
        let workspace = try Workspace(root: root)
        let xml = try value.encoded(format: .xml)
        let snapshot = try await workspace.importDocument(data: xml, name: "Original.plist")
        var changed = value; try changed.set(.string("new"), at: ["CacheExtra", "test"])
        let saved = try await workspace.commit(changed, expected: snapshot)
        XCTAssertEqual(saved.value, changed)
        let state = await workspace.listing()
        let restored = try await workspace.restore(state.backups.first { $0.reason == "Imported baseline" }!.id, expected: saved)
        XCTAssertEqual(restored.data, xml)
        let final = await workspace.listing()
        XCTAssertEqual(final.backups.count, 3)
    }
    func testStaleWindowCannotOverwriteOtherWindow() async throws {
        let workspace = try Workspace(root: root)
        let snapshot = try await workspace.importDocument(data: value.encoded(), name: "Shared.plist")
        _ = try await workspace.commit(.dictionary(["one": .integer(1)]), expected: snapshot)
        do { _ = try await workspace.commit(.dictionary(["two": .integer(2)]), expected: snapshot); XCTFail("Expected conflict") }
        catch { XCTAssertEqual(error as? ElyraError, .conflict) }
    }
    func testConcurrentSavesOnlyOneCanCommit() async throws {
        let workspace = try Workspace(root: root)
        let snapshot = try await workspace.importDocument(data: value.encoded(), name: "Race.plist")
        let successes = await withTaskGroup(of: Bool.self) { group in
            for index in 0..<12 {
                group.addTask { do { _ = try await workspace.commit(.dictionary(["index": .integer(Int64(index))]), expected: snapshot); return true } catch { return false } }
            }
            var count = 0; for await succeeded in group { if succeeded { count += 1 } }; return count
        }
        XCTAssertEqual(successes, 1)
    }
    func testTamperedSameSizeBackupIsRejectedBeforeRestore() async throws {
        let workspace = try Workspace(root: root)
        let snapshot = try await workspace.importDocument(data: value.encoded(), name: "Sensitive.plist")
        let state = await workspace.listing(); let record = state.backups[0]
        let target = root.appendingPathComponent("Backups/" + record.filename)
        var bytes = try Data(contentsOf: target); bytes[bytes.count / 2] ^= 1
        try bytes.write(to: target)
        do { _ = try await workspace.restore(record.id, expected: snapshot); XCTFail("Expected integrity error") } catch { XCTAssertEqual(error as? ElyraError, .integrity) }
        let read = try await workspace.snapshot(snapshot.record.id)
        XCTAssertEqual(read.data, snapshot.data)
    }
    func testCrossDocumentBackupRejected() async throws {
        let workspace = try Workspace(root: root)
        _ = try await workspace.importDocument(data: value.encoded(), name: "A.plist")
        let state = await workspace.listing()
        let other = try await workspace.importDocument(data: value.encoded(), name: "B.plist")
        do { _ = try await workspace.restore(state.backups[0].id, expected: other); XCTFail("Cross-document restore allowed") } catch { }
    }
    func testAssetTrashRestoreAndTamperCheck() async throws {
        let workspace = try Workspace(root: root)
        let data = Data("actual asset".utf8)
        let asset = try await workspace.importAsset(data: data, name: "../../test.txt", category: "Files")
        let url = try await workspace.assetURL(asset.id)
        XCTAssertEqual(try Data(contentsOf: url), data)
        XCTAssertTrue(url.path.hasPrefix(root.path + "/Assets/"))
        try await workspace.deleteAsset(asset.id)
        let deleted = await workspace.listing(); XCTAssertEqual(deleted.trash.count, 1)
        try await workspace.restoreAsset(asset.id)
        let restored = try await workspace.assetURL(asset.id)
        try Data("tampered".utf8).write(to: restored)
        do { _ = try await workspace.assetURL(asset.id); XCTFail("Expected integrity rejection") } catch { XCTAssertEqual(error as? ElyraError, .integrity) }
    }
    func testDraftsIsolatedByWindowAndPersistTypes() async throws {
        let workspace = try Workspace(root: root)
        let doc = UUID(), a = UUID(), b = UUID()
        try await workspace.saveDraft(LocalDraft(revision: "r1", value: value), window: a, document: doc)
        let draft = try await workspace.loadDraft(window: a, document: doc)
        let absent = try await workspace.loadDraft(window: b, document: doc)
        XCTAssertEqual(draft?.value, value); XCTAssertNil(absent)
        try await workspace.discardDraft(window: a, document: doc)
        let discarded = try await workspace.loadDraft(window: a, document: doc)
        XCTAssertNil(discarded)
    }
    func testBackupFailurePreventsSave() async throws {
        let workspace = try Workspace(root: root)
        let snapshot = try await workspace.importDocument(data: value.encoded(), name: "BackupRequired.plist")
        let backups = root.appendingPathComponent("Backups")
        try FileManager.default.removeItem(at: backups)
        try Data("not a directory".utf8).write(to: backups)
        do { _ = try await workspace.commit(.dictionary(["changed": .boolean(true)]), expected: snapshot); XCTFail("Expected backup failure") } catch { }
        let current = try await workspace.snapshot(snapshot.record.id)
        XCTAssertEqual(current.data, snapshot.data)
    }
    func testJournalRecoversAfterFileWriteBeforeIndexUpdate() async throws {
        struct Journal: Encodable {
            let document: DocumentRecord
            let expected: String
            let desired: String
            let state: WorkspaceState
        }
        let workspace = try Workspace(root: root)
        let snapshot = try await workspace.importDocument(data: value.encoded(), name: "Interrupted.plist")
        let output = try PlistValue.dictionary(["saved": .boolean(true)]).encoded()
        let state = await workspace.listing()
        let journal = Journal(document: snapshot.record, expected: snapshot.revision, desired: Digest.sha256(output), state: state)
        try JSONEncoder().encode(journal).write(to: root.appendingPathComponent("commit.json"))
        try output.write(to: root.appendingPathComponent("Documents/" + snapshot.record.filename))
        let reopened = try Workspace(root: root)
        let recovered = try await reopened.snapshot(snapshot.record.id)
        XCTAssertEqual(recovered.data, output)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("commit.json").path))
    }
    func testPendingRecoveryJournalBlocksFurtherCommit() async throws {
        let workspace = try Workspace(root: root)
        let snapshot = try await workspace.importDocument(data: value.encoded(), name: "Locked.plist")
        try Data("unresolved journal".utf8).write(to: root.appendingPathComponent("commit.json"))
        do {
            _ = try await workspace.commit(.dictionary(["later": .integer(2)]), expected: snapshot)
            XCTFail("Unresolved recovery must not be overwritten")
        } catch { }
        do {
            _ = try await workspace.importAsset(data: Data("asset".utf8), name: "Blocked.txt", category: "Files")
            XCTFail("Pending recovery must also block library mutations")
        } catch { }
        let current = try await workspace.snapshot(snapshot.record.id)
        XCTAssertEqual(current.data, snapshot.data)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("commit.json")), Data("unresolved journal".utf8))
    }
    func testCorruptIndexDoesNotSilentlyResetLibrary() async throws {
        _ = try Workspace(root: root)
        try Data("broken".utf8).write(to: root.appendingPathComponent("index.json"))
        XCTAssertThrowsError(try Workspace(root: root))
    }
}
