// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore

final class DynamicIslandTests: XCTestCase {
    let flag = DynamicIslandEngine.flagKey
    let artwork = DynamicIslandEngine.artworkKey
    let subtype = DynamicIslandEngine.subtypeKey
    func document(extra: [String: PlistValue] = [:]) -> PlistValue {
        .dictionary(["CacheUUID": .string("ABC-123"), "CacheVersion": .integer(1), "CacheData": .data(Data([1,2,3])), "CacheExtra": .dictionary(extra)])
    }
    func testFlagTypesAndIPadArtworkAreReportedWithoutClaimingEffect() throws {
        for (value, expected) in [(PlistValue.boolean(true), IslandFlag.enabled), (.integer(1), .enabled), (.integer(0), .disabled), (.boolean(false), .disabled), (.real(1), .invalid), (.string("true"), .invalid)] {
            let inspected = try DynamicIslandEngine.inspect(document(extra: [flag: value, artwork: .dictionary([subtype: .integer(2736)])]), physicalHardware: "iPad14,1")
            XCTAssertEqual(inspected.flag, expected)
            XCTAssertTrue(inspected.isIPad)
            XCTAssertTrue(inspected.usesPhoneArtwork)
        }
        XCTAssertEqual(try DynamicIslandEngine.inspect(document(), physicalHardware: "iPad14,2").flag, .absent)
    }
    func testEnableFlagDoesNotChangeSubtypeIdentityOrRoot() throws {
        let original = document(extra: [artwork: .dictionary([subtype: .integer(2436), "ArtworkDeviceProductDescription": .string("Mini")])])
        let target = try DynamicIslandEngine.enablingFlag(in: original)
        let changes = PlistChange.between(original, target)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes[0].path, ["CacheExtra", flag])
        let enabledBool = document(extra: [flag: .boolean(true)])
        XCTAssertEqual(try DynamicIslandEngine.enablingFlag(in: enabledBool), enabledBool)
    }
    func testRestoreRemovesOriginallyAbsentFieldsAndPreservesArtworkName() throws {
        let original = document()
        let current = document(extra: [flag: .integer(1), artwork: .dictionary([subtype: .integer(2736), "ArtworkDeviceProductDescription": .string("Custom name")]), "unrelated": .integer(9)])
        let target = try DynamicIslandEngine.restoringRecordedFields(in: current, baseline: original)
        XCTAssertNil(target.value(at: ["CacheExtra", flag]))
        XCTAssertNil(target.value(at: ["CacheExtra", artwork, subtype]))
        XCTAssertEqual(target.value(at: ["CacheExtra", artwork, "ArtworkDeviceProductDescription"]), .string("Custom name"))
        XCTAssertEqual(target.value(at: ["CacheExtra", "unrelated"]), .integer(9))
    }
    func testRestorePreservesExactOriginalTypesAndEmptyArtworkPresence() throws {
        let original = document(extra: [flag: .boolean(false), artwork: .dictionary([:])])
        let current = document(extra: [flag: .integer(1), artwork: .dictionary([subtype: .integer(2556)])])
        XCTAssertEqual(try DynamicIslandEngine.restoringRecordedFields(in: current, baseline: original), original)
        let missingArtwork = document()
        let restored = try DynamicIslandEngine.restoringRecordedFields(in: current, baseline: missingArtwork)
        XCTAssertNil(restored.value(at: ["CacheExtra", artwork]))
    }
    func testMismatchedCacheGenerationIsRejectedAndCaseIsAccepted() throws {
        let original = document()
        for (key, value) in [("CacheUUID", PlistValue.string("different")), ("CacheVersion", .integer(2)), ("CacheData", .data(Data([1])))] {
            var current = document(extra: [flag: .integer(1)])
            try current.set(value, at: [key])
            XCTAssertThrowsError(try DynamicIslandEngine.restoringRecordedFields(in: current, baseline: original))
        }
        var current = document(extra: [flag: .integer(1)])
        try current.set(.string("abc-123"), at: ["CacheUUID"])
        let restored = try DynamicIslandEngine.restoringRecordedFields(in: current, baseline: original)
        XCTAssertNil(restored.value(at: ["CacheExtra", flag]))
        XCTAssertEqual(restored.value(at: ["CacheUUID"]), .string("abc-123"))
    }
    func testMalformedArtworkAndNonGestaltDocumentsAreRejected() throws {
        let broken = document(extra: [artwork: .string("invalid")])
        XCTAssertFalse(try DynamicIslandEngine.inspect(broken, physicalHardware: "iPad14,1").artworkIsValid)
        XCTAssertThrowsError(try DynamicIslandEngine.enablingFlag(in: broken))
        XCTAssertThrowsError(try DynamicIslandEngine.restoringRecordedFields(in: broken, baseline: document()))
        XCTAssertThrowsError(try DynamicIslandEngine.inspect(.array([]), physicalHardware: "iPad14,1"))
    }
}
final class IslandWorkspaceTests: XCTestCase, @unchecked Sendable {
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    override func tearDown() { try? FileManager.default.removeItem(at: root) }
    func testTargetedPlanUsesItsOwnVerifiedBaselineAndRemainsStaged() async throws {
        let w = try Workspace(root: root)
        let baseline: PlistValue = .dictionary(["CacheExtra": .dictionary(["unrelated": .integer(1)])])
        let imported = try await w.importDocument(data: baseline.encoded(), name: "Mini.plist")
        let plan = try await w.islandPlan(documentID: imported.record.id, action: .enableFlag)
        let unchanged = try await w.snapshot(imported.record.id)
        XCTAssertEqual(unchanged.data, imported.data)
        _ = try await w.commit(plan.target, expected: plan.snapshot)
        let restore = try await w.islandPlan(documentID: imported.record.id, action: .restoreBaseline)
        XCTAssertEqual(restore.target, baseline)
        XCTAssertEqual(restore.baseline?.documentID, imported.record.id)
        _ = try await w.commit(.dictionary(["CacheExtra": .dictionary(["changed": .boolean(true)])]), expected: restore.snapshot)
        do { _ = try await w.commit(restore.target, expected: restore.snapshot); XCTFail("Stale plan committed") }
        catch { XCTAssertEqual(error as? ElyraError, .conflict) }
    }
    func testCorruptBaselineIsNotUsedAsARecoverySource() async throws {
        let w = try Workspace(root: root)
        let imported = try await w.importDocument(data: PlistValue.dictionary(["CacheExtra": .dictionary([:])]).encoded(), name: "Mini.plist")
        let state = await w.listing()
        try Data("corrupt backup".utf8).write(to: root.appendingPathComponent("Backups/" + state.backups[0].filename))
        do { _ = try await w.islandPlan(documentID: imported.record.id, action: .restoreBaseline); XCTFail("Corrupt original accepted") }
        catch { XCTAssertEqual(error as? ElyraError, .integrity) }
    }
    func testObservationExportLabelsSimulatorAndNeverExposesFullPlist() async throws {
        let w = try Workspace(root: root)
        let observation = IslandObservation(hardware: "iPad14,1", osVersion: "iPadOS 27.0", build: "unknown-build", simulator: true,
                                            activity: .compact, orientation: .landscape, playing: true, outcome: .tall, notes: "test observation")
        try await w.recordIslandObservation(observation)
        let reopened = try Workspace(root: root)
        let state = await reopened.listing()
        XCTAssertEqual(state.islandObservations.count, 1)
        XCTAssertTrue(state.islandObservations[0].simulator)
        let json = try await reopened.exportResearchReport()
        let parsed = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: Any])
        let rows = try XCTUnwrap(parsed["observations"] as? [[String: Any]])
        XCTAssertEqual(rows[0]["simulator"] as? Bool, true)
        XCTAssertNil(parsed["documents"])
        XCTAssertTrue((parsed["scope"] as? String)?.contains("not automated proof") == true)
    }
    func testObservationCannotAttachToStaleOrMissingDocument() async throws {
        let w = try Workspace(root: root)
        let imported = try await w.importDocument(data: PlistValue.dictionary([:]).encoded(), name: "A.plist")
        _ = try await w.commit(.dictionary(["x": .integer(1)]), expected: imported)
        let observation = IslandObservation(hardware: "iPad14,1", osVersion: "iPadOS 27.0", build: "unknown", simulator: false,
                                            activity: .multiple, orientation: .landscape, playing: true, outcome: .other, notes: "",
                                            documentID: imported.record.id, documentRevision: imported.revision)
        do { try await w.recordIslandObservation(observation); XCTFail("Stale document evidence accepted") }
        catch { XCTAssertEqual(error as? ElyraError, .conflict) }
    }
    func testVersionOneLibraryMigratesWithoutLosingExistingRecords() async throws {
        let w = try Workspace(root: root)
        let imported = try await w.importDocument(data: PlistValue.dictionary([:]).encoded(), name: "Kept.plist")
        let state = await w.listing()
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        legacy.removeValue(forKey: "schemaVersion"); legacy.removeValue(forKey: "islandObservations")
        try JSONSerialization.data(withJSONObject: legacy).write(to: root.appendingPathComponent("index.json"))
        let reopened = try Workspace(root: root)
        let migrated = await reopened.listing()
        XCTAssertEqual(migrated.documents.map(\.id), [imported.record.id])
        XCTAssertEqual(migrated.backups.count, 1)
        XCTAssertEqual(migrated.schemaVersion, 3)
        XCTAssertTrue(migrated.islandObservations.isEmpty)
    }
    func testFutureLibrarySchemaFailsClosed() throws {
        let data = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(WorkspaceState.self, from: data))
    }
    func testNonMediaActivitiesKeepPlaybackUnspecifiedAndRoundnessEvidence() async throws {
        let w = try Workspace(root: root)
        for activity in [IslandActivity.idle, .recording, .timer, .call, .navigation, .other] {
            XCTAssertFalse(activity.canIncludeMedia)
            let observation = IslandObservation(hardware: "iPad14,1", osVersion: "iPadOS 27.0", build: "unknown", simulator: false,
                                                activity: activity, orientation: .portrait, playing: nil, outcome: .corners, notes: "User observation only")
            try await w.recordIslandObservation(observation)
        }
        let reopened = try Workspace(root: root)
        let state = await reopened.listing()
        XCTAssertEqual(state.islandObservations.count, 6)
        XCTAssertTrue(state.islandObservations.allSatisfy { $0.playing == nil && $0.outcome == .corners })
        let data = try await reopened.exportResearchReport()
        let parsed = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(parsed["schemaVersion"] as? Int, 2)
        let rows = try XCTUnwrap(parsed["observations"] as? [[String: Any]])
        XCTAssertTrue(rows.allSatisfy { $0["playing"] == nil })
    }
    func testVersionTwoObservationsRetainLegacyPlaybackAndMigrateToVersionThree() async throws {
        let w = try Workspace(root: root)
        let observation = IslandObservation(hardware: "iPad14,1", osVersion: "Version 26.2", build: "23C54", simulator: true,
                                            activity: .compact, orientation: .landscape, playing: false, outcome: .tall, notes: "Legacy")
        try await w.recordIslandObservation(observation)
        let state = await w.listing()
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        legacy["schemaVersion"] = 2
        try JSONSerialization.data(withJSONObject: legacy).write(to: root.appendingPathComponent("index.json"))
        let reopened = try Workspace(root: root)
        let migrated = await reopened.listing()
        XCTAssertEqual(migrated.schemaVersion, 3)
        XCTAssertEqual(migrated.islandObservations[0].id, observation.id)
        XCTAssertEqual(migrated.islandObservations[0].playing, false)
        XCTAssertEqual(migrated.islandObservations[0].activity, .compact)
    }
}
