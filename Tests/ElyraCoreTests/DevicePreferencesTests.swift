// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore
final class DevicePreferencesTests: XCTestCase {
    func fixture() -> PlistValue { .dictionary(["CacheData": .data(Data([1,2,3])), "CacheExtra": .dictionary(["VasUgeSzVyHdB27g2XpN0g": .string("SYNTHETIC"), DevicePreferences.regionCode: .string("CH"), "zHeENZu+wbg7PUprwNwBWg": .string("CH/A"), "K/R1GfGfCkXvEhaPS2Vrng": .data(Data([3,8]))])]) }
    func testIntelligenceRecipePreservesSalesRegionIdentityAndDeviceSpecificSiri() throws {
        let before=fixture(), after=try DevicePreferences.applying(.intelligenceMainland,to:before)
        for feature in DevicePreferences.intelligence { XCTAssertEqual(feature.state(in:after),.enabled) }
        XCTAssertEqual(after.value(at:["CacheExtra",DevicePreferences.regionCode]),.string("LL"))
        for key in ["zHeENZu+wbg7PUprwNwBWg","VasUgeSzVyHdB27g2XpN0g","K/R1GfGfCkXvEhaPS2Vrng"] { XCTAssertEqual(after.value(at:["CacheExtra",key]),before.value(at:["CacheExtra",key])) }
        XCTAssertEqual(after.value(at:["CacheData"]),before.value(at:["CacheData"]))
        XCTAssertNoThrow(try SystemEditPolicy.validate(after,from:before))
        XCTAssertEqual(try DevicePreferences.applying(.restoreIntelligence,to:after,original:before),before)
    }
    func testModelNameSynchronizesAllDisplayFieldsAndPreservesArtwork() throws {
        var before=fixture();try before.set(.dictionary(["ArtworkDeviceSubType":.integer(2062),"other":.string("keep")]),at:["CacheExtra",DynamicIslandEngine.artworkKey])
        let after=try DevicePreferences.applying(.modelName("  Example Tablet  "),to:before)
        for path in DevicePreferences.modelNamePaths { XCTAssertEqual(after.value(at:path),.string("Example Tablet")) }
        XCTAssertEqual(after.value(at:["CacheExtra",DynamicIslandEngine.artworkKey,"ArtworkDeviceSubType"]),.integer(2062))
        XCTAssertNoThrow(try SystemEditPolicy.validate(after,from:before))
        XCTAssertEqual(try DevicePreferences.applying(.restoreModelName,to:after,original:before),before)
    }
    func testAbsentArtworkIsCreatedAndRestoredWithoutFabricatedValues() throws {
        let before=fixture(),after=try DevicePreferences.applying(.modelName("Example"),to:before)
        XCTAssertEqual(try DevicePreferences.applying(.restoreModelName,to:after,original:before),before)
        XCTAssertEqual(try DevicePreferences.applying(.restoreModelName,to:before,original:before),before)
        for invalid in ["", " ", "bad\nname", String(repeating:"a",count:257)] { XCTAssertThrowsError(try DevicePreferences.applying(.modelName(invalid),to:before)) }
        var malformed=before;try malformed.set(.integer(4),at:["CacheExtra",DynamicIslandEngine.artworkKey]);XCTAssertThrowsError(try DevicePreferences.applying(.modelName("Example"),to:malformed))
    }
    func testStateUsesValuesRatherThanExactPresetAndDoesNotGuessUnknownTypes() throws {
        var value=fixture();let aod=Capability.all.first{$0.id=="aod"}!,parallax=Capability.all.first{$0.id=="parallax"}!,count=Capability.all.first{$0.id=="aodFlipbookCount"}!,siri=Capability.all.first{$0.id=="siriOnDevice"}!
        XCTAssertEqual(aod.state(in:nil),.unread);XCTAssertEqual(aod.state(in:value),.disabled)
        try value.set(.boolean(true),at:["CacheExtra",aod.keys[0]]);XCTAssertEqual(aod.state(in:value),.mixed)
        try aod.stage(in:&value);XCTAssertEqual(aod.state(in:value),.enabled)
        try aod.stageDisabled(in:&value);XCTAssertEqual(aod.state(in:value),.disabled);XCTAssertEqual(value.value(at:["CacheExtra",aod.keys[0]]),.boolean(false))
        try parallax.stage(in:&value);XCTAssertEqual(parallax.state(in:value),.enabled);try parallax.stageDisabled(in:&value);XCTAssertEqual(parallax.state(in:value),.disabled)
        try value.set(.integer(2),at:["CacheExtra",count.keys[0]]);XCTAssertEqual(count.state(in:value),.enabled)
        XCTAssertEqual(siri.state(in:value),.unknown);XCTAssertThrowsError(try siri.stageDisabled(in:&value))
    }
    func testPolicyKeepsHardwareAndBinaryFieldsProtected() throws {
        for key in ["VasUgeSzVyHdB27g2XpN0g","97JDvERpVwO+GHtthIh7hA","h9jDsbgj7xIVeIQ8S3/X3Q"] {
            var after=fixture();try after.set(.string("different"),at:["CacheExtra",key]);XCTAssertThrowsError(try SystemEditPolicy.validate(after,from:fixture()))
        }
        var after=fixture();try after.set(.string("UNSUPPORTED"),at:["CacheExtra",DevicePreferences.regionCode]);XCTAssertThrowsError(try SystemEditPolicy.validate(after,from:fixture()))
    }
    func testRegionCodeChangesOnlyCodeAndRestoresRecordedUnknownValue() throws {
        var before = fixture()
        try before.set(.string("RECORDED"), at: ["CacheExtra", DevicePreferences.regionCode])
        for code in DevicePreferences.regionCodes {
            let after = try DevicePreferences.applying(.regionCode(code), to: before)
            XCTAssertEqual(PlistChange.between(before, after).map(\.path), [["CacheExtra", DevicePreferences.regionCode]])
            XCTAssertEqual(DevicePreferences.currentRegionCode(in: after), code)
            XCTAssertNoThrow(try SystemEditPolicy.validate(after, from: before))
            let restored = try DevicePreferences.applying(.restoreRegionCode, to: after, original: before)
            XCTAssertEqual(restored, before)
            XCTAssertNoThrow(try SystemEditPolicy.validate(restored, from: after, restoring: true))
        }
        for code in ["", "UNSUPPORTED", "ll", "LL/A", "CH\n"] {
            XCTAssertThrowsError(try DevicePreferences.applying(.regionCode(code), to: before))
        }
        XCTAssertThrowsError(try DevicePreferences.applying(.restoreRegionCode, to: before))
    }
    func testRegionRestorePreservesUnrelatedIntelligenceAndNameChanges() throws {
        let before = fixture()
        var absent = before
        try absent.set(nil, at: ["CacheExtra", DevicePreferences.regionCode])
        let configured = try DevicePreferences.applying(.modelName("Example"), to: DevicePreferences.applying(.intelligenceMainland, to: absent))
        let restored = try DevicePreferences.applying(.restoreRegionCode, to: configured, original: absent)
        XCTAssertNil(DevicePreferences.currentRegionCode(in: restored))
        XCTAssertEqual(DevicePreferences.modelName(in: restored), "Example")
        for feature in DevicePreferences.intelligence { XCTAssertEqual(feature.state(in: restored), .enabled) }
        XCTAssertEqual(try SystemEditPolicy.generation(configured), try SystemEditPolicy.generation(restored))
    }
}
