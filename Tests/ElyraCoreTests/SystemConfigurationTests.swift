// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore

private final class TestSystemDisk: SystemConfigurationFile, @unchecked Sendable {
    let url: URL
    var identity = UUID().uuidString
    var writes = 0
    var failFirst = false
    var failAll = false
    var denyWrite = false
    init(root: URL, data: Data) throws { url = root.appendingPathComponent("synthetic-cache.plist"); try data.write(to: url) }
    func read() throws -> Data { try Data(contentsOf: url) }
    func replace(_ data: Data) throws {
        writes += 1
        if failAll || (failFirst && writes == 1) {
            try data.prefix(3).write(to: url)
            throw ElyraError.invalid("Injected write failure")
        }
        try data.write(to: url)
    }
    func close() {}
    var access: SystemAccess { SystemAccess { writable in if writable && self.denyWrite { throw ElyraError.systemUnavailable }; return self } }
}
final class SystemConfigurationTests: XCTestCase, @unchecked Sendable {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let flag = DynamicIslandEngine.flagKey
    override func setUp() { try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    override func tearDown() { try? FileManager.default.removeItem(at: root) }
    func original() -> PlistValue { .dictionary(["CacheUUID": .string("synthetic-cache"), "CacheData": .data(Data([1,2,3])), "CacheExtra": .dictionary(["protected-identity": .string("fixture")])]) }
    private func make(xml: Bool = false) throws -> (SystemConfigurationStore, TestSystemDisk) {
        let disk = try TestSystemDisk(root: root, data: original().encoded(format: xml ? .xml : .binary))
        return (try SystemConfigurationStore(root: root.appendingPathComponent("backups"), binding: "synthetic-installation", access: disk.access), disk)
    }
    func edit(_ before: PlistValue) throws -> PlistValue { try DynamicIslandEngine.enablingFlag(in: before) }
    func testDirectCaptureWriteReadbackAndExactXMLRestore() async throws {
        let (store,disk) = try make(xml: true);let bytes = try disk.read()
        let snapshot = try await store.connect();let records = await store.listing()
        XCTAssertTrue(snapshot.writable);XCTAssertEqual(records.count,1)
        let saved = try await store.apply(edit(snapshot.value), expected: snapshot)
        XCTAssertEqual(try disk.read(),saved.data);XCTAssertTrue(saved.data.starts(with: Data("<?xml".utf8)))
        let restored = try await store.restore(records[0].id, expected: saved)
        XCTAssertEqual(restored.data,bytes);XCTAssertEqual(try disk.read(),bytes)
    }
    func testStaleSessionAndExternalChangesAreRejectedBeforeWriting() async throws {
        let (store,disk) = try make();let first = try await store.connect();_ = try await store.connect()
        do { _ = try await store.apply(edit(first.value), expected: first);XCTFail() } catch { XCTAssertEqual(error as? ElyraError,.conflict) }
        let current = try await store.connect();try Data("external".utf8).write(to: disk.url)
        do { _ = try await store.apply(edit(current.value),expected:current);XCTFail() } catch { XCTAssertEqual(error as? ElyraError,.conflict) }
        XCTAssertEqual(disk.writes,0)
    }
    func testProtectedIdentityAndRootCacheChangesAreRejected() throws {
        var value = original();try value.set(.string("changed"),at:["CacheExtra","protected-identity"])
        XCTAssertThrowsError(try SystemEditPolicy.validate(value,from:original()))
        value = original();try value.set(.data(Data([9])),at:["CacheData"])
        XCTAssertThrowsError(try SystemEditPolicy.validate(value,from:original()))
    }
    func testCorruptBackupCannotBeRestored() async throws {
        let (store,disk) = try make();let before = try await store.connect();let records = await store.listing()
        let saved = try await store.apply(edit(before.value),expected:before)
        try Data("broken".utf8).write(to:root.appendingPathComponent("backups").appendingPathComponent(records[0].filename))
        do { _ = try await store.restore(records[0].id,expected:saved);XCTFail() } catch { XCTAssertEqual(error as? ElyraError,.integrity) }
        XCTAssertEqual(try disk.read(),saved.data)
    }
    func testPartialWriteFailureRestoresPreviousBytes() async throws {
        let (store,disk) = try make();let before = try await store.connect();disk.failFirst = true
        do { _ = try await store.apply(edit(before.value),expected:before);XCTFail() } catch {}
        XCTAssertEqual(try disk.read(),before.data);XCTAssertEqual(disk.writes,2)
        let pending = await store.recoveryPending();XCTAssertFalse(pending)
    }
    func testRollbackFailureBlocksWritesAndAllowsVerifiedRecovery() async throws {
        let (store,disk) = try make();let before = try await store.connect();disk.failAll = true
        do { _ = try await store.apply(edit(before.value),expected:before);XCTFail() } catch {}
        let pending = await store.recoveryPending();XCTAssertTrue(pending)
        do { _ = try await store.connect();XCTFail() } catch {}
        disk.failAll = false;try await store.recoverInterruptedWrite()
        XCTAssertEqual(try disk.read(),before.data)
        let cleared = await store.recoveryPending();XCTAssertFalse(cleared)
    }
    func testRecoveryJournalSurvivesReopening() async throws {
        let (store,disk) = try make();let before = try await store.connect();disk.failAll = true
        do { _ = try await store.apply(edit(before.value),expected:before);XCTFail() } catch {}
        disk.failAll = false
        let reopened = try SystemConfigurationStore(root:root.appendingPathComponent("backups"),binding:"synthetic-installation",access:disk.access)
        try await reopened.recoverInterruptedWrite();XCTAssertEqual(try disk.read(),before.data)
    }
    func testReplacedCacheIsNotOverwrittenDuringRecovery() async throws {
        let (store,disk) = try make();let before = try await store.connect();disk.failAll = true
        do { _ = try await store.apply(edit(before.value),expected:before);XCTFail() } catch {}
        disk.failAll = false;disk.identity = "replacement"
        do { try await store.recoverInterruptedWrite();XCTFail() } catch {}
        XCTAssertEqual(try disk.read().count,3)
    }
    func testReadOnlyProbeDoesNotPretendToGrantWrites() async throws {
        let (store,disk) = try make();disk.denyWrite = true;let snapshot = try await store.connect()
        XCTAssertFalse(snapshot.writable);XCTAssertNotNil(snapshot.accessError)
        do { _ = try await store.apply(edit(snapshot.value),expected:snapshot);XCTFail() } catch {}
        XCTAssertEqual(disk.writes,0)
    }
    func testBackupBindingPreventsCrossInstallationRestore() async throws {
        let (store,disk) = try make();_ = try await store.connect();let records = await store.listing()
        let other = try SystemConfigurationStore(root:root.appendingPathComponent("backups"),binding:"other-installation",access:disk.access)
        let current = try await other.connect()
        do { _ = try await other.restore(records[0].id,expected:current);XCTFail() } catch {}
        XCTAssertEqual(disk.writes,0)
    }
    func testGenerationHashUsesCanonicalDictionaryOrder() throws {
        let a:PlistValue = .dictionary(["CacheExtra":.dictionary(["a":.integer(1),"b":.integer(2)]),"CacheUUID":.string("fixture")])
        let b:PlistValue = .dictionary(["CacheUUID":.string("fixture"),"CacheExtra":.dictionary(["b":.integer(2),"a":.integer(1)])])
        XCTAssertEqual(try SystemEditPolicy.generation(a),try SystemEditPolicy.generation(b))
    }
    func testUnsupportedFlagTypesAndUnknownSubtypesAreRejected() throws {
        var value = original();try value.set(.string("true"),at:["CacheExtra",flag])
        XCTAssertThrowsError(try SystemEditPolicy.validate(value,from:original()))
        value = original();try value.set(.dictionary([DynamicIslandEngine.subtypeKey:.integer(9999)]),at:["CacheExtra",DynamicIslandEngine.artworkKey])
        XCTAssertThrowsError(try SystemEditPolicy.validate(value,from:original()))
    }
    func testConcurrentWindowsOnlyOneRevisionCanCommit() async throws {
        let (store,disk) = try make();let before = try await store.connect();let target = try edit(before.value)
        let count = await withTaskGroup(of:Bool.self) { group in
            for _ in 0..<2 { group.addTask { (try? await store.apply(target,expected:before)) != nil } }
            var successes=0;for await success in group { if success { successes += 1 } };return successes
        }
        XCTAssertEqual(count,1);XCTAssertEqual(disk.writes,1)
    }
    func testChangedGenerationBlocksRecoveryEvenAtSameFileIdentity() async throws {
        let (store,disk) = try make();let before = try await store.connect();disk.failAll = true
        do { _ = try await store.apply(edit(before.value),expected:before);XCTFail() } catch {}
        disk.failAll = false;var changed = original();try changed.set(.string("new-generation"),at:["CacheUUID"]);try changed.encoded().write(to:disk.url)
        do { try await store.recoverInterruptedWrite();XCTFail() } catch {}
        XCTAssertEqual(try PlistValue.decode(disk.read()),changed)
    }
    func testFeatureApplyAndRestoreUseCapturedOriginalAndPreserveOtherChanges() async throws {
        let (store,disk) = try make();let before = try await store.connect()
        let enable = try await store.capabilityPlan("dynamicIsland", restoring: false, expected: before)
        XCTAssertEqual(enable.changes.count,1)
        var saved = try await store.commitCapability(enable)
        var other = saved.value;try Capability.all.first { $0.id == "aod" }!.stage(in:&other)
        saved = try await store.apply(other,expected:saved)
        let restore = try await store.capabilityPlan("dynamicIsland",restoring:true,expected:saved)
        XCTAssertNil(restore.target.value(at:["CacheExtra",flag]))
        let restored = try await store.commitCapability(restore)
        XCTAssertNil(restored.value.value(at:["CacheExtra",flag]))
        XCTAssertEqual(restored.value.value(at:["CacheExtra","2OOJf1VhaM7NxfRok3HbWQ"]),.integer(1))
        XCTAssertEqual(try disk.read(),restored.data)
    }
    func testFeaturePlansRejectStaleSessionAndCorruptOriginal() async throws {
        let (store,_) = try make();let before = try await store.connect()
        let plan = try await store.capabilityPlan("dynamicIsland",restoring:false,expected:before)
        _ = try await store.connect()
        do { _ = try await store.commitCapability(plan);XCTFail() } catch {}
        let current = try await store.connect();let backups = await store.listing()
        try Data("corrupt".utf8).write(to:root.appendingPathComponent("backups").appendingPathComponent(backups[0].filename))
        do { _ = try await store.capabilityPlan("dynamicIsland",restoring:true,expected:current);XCTFail() } catch { XCTAssertEqual(error as? ElyraError,.integrity) }
    }
    func testDeviceSpecificSiriPresetCannotBypassValidationViaPlan() async throws {
        let (store,_) = try make();let current = try await store.connect()
        do { _ = try await store.capabilityPlan("siriOnDevice",restoring:false,expected:current);XCTFail() } catch {}
    }

}
