// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore
final class ConfigurationPlanTests: XCTestCase {
    func testPlanValidationAndImportRegeneratesIdentity() throws {
        let plan = ConfigurationPlan(name: "  Display preset  ", steps: [.init(capabilityID: "aod", action: .apply)])
        let data = try plan.encoded(); let imported = try ConfigurationPlan.imported(data)
        XCTAssertEqual(imported.name,"Display preset");XCTAssertEqual(imported.steps,plan.steps);XCTAssertNotEqual(imported.id,plan.id)
        let object = try JSONSerialization.jsonObject(with:data) as! [String:Any]
        XCTAssertEqual(Set(object.keys),["schemaVersion","id","name","steps"])
        XCTAssertThrowsError(try ConfigurationPlan(name:"",steps:[]).validate())
        XCTAssertThrowsError(try ConfigurationPlan(name:"Unknown",steps:[.init(capabilityID:"unknown",action:.apply)]).validate())
        XCTAssertThrowsError(try ConfigurationPlan(name:"Duplicate",steps:[.init(capabilityID:"aod",action:.apply),.init(capabilityID:"aod",action:.restore)]).validate())
        XCTAssertThrowsError(try ConfigurationPlan.imported(Data(repeating:0,count:ConfigurationPlan.maximumBytes+1)))
        var changed=object;changed["schemaVersion"]=99
        XCTAssertThrowsError(try ConfigurationPlan.imported(JSONSerialization.data(withJSONObject:changed)))
    }
    func testWorkspacePlanPersistenceDoesNotOverwriteImports() async throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:root) }
        let workspace=try Workspace(root:root)
        let plan=ConfigurationPlan(name:"Display",steps:[.init(capabilityID:"aod",action:.apply)])
        try await workspace.saveConfigurationPlan(plan)
        let imported=try ConfigurationPlan.imported(plan.encoded());try await workspace.saveConfigurationPlan(imported)
        let reopened=try Workspace(root:root);let plans=try await reopened.configurationPlans()
        XCTAssertEqual(Set(plans.map(\.id)),[plan.id,imported.id])
        try await reopened.deleteConfigurationPlan(plan.id)
        let remaining=try await reopened.configurationPlans();XCTAssertEqual(remaining,[imported])
    }
    func testBooleanPresetsKeepTheirOriginalTypeAndNoopValue() throws {
        let aod=Capability.all.first { $0.id=="aod" }!
        var value:PlistValue = .dictionary(["CacheExtra":.dictionary(Dictionary(uniqueKeysWithValues:aod.keys.map { ($0,.boolean(true)) }))])
        let original=value;try aod.stage(in:&value);XCTAssertEqual(value,original)
        let parallax=Capability.all.first { $0.id=="parallax" }!
        try value.set(.boolean(true),at:["CacheExtra",parallax.keys[0]]);try parallax.stage(in:&value)
        XCTAssertEqual(value.value(at:["CacheExtra",parallax.keys[0]]),.boolean(false))
    }
    func testDraftRebaseMergesUnrelatedFieldsAndRejectsOverlaps() throws {
        let base:PlistValue = .dictionary(["a":.integer(1),"b":.integer(2)])
        let draft:PlistValue = .dictionary(["a":.integer(3),"b":.integer(2)])
        let current:PlistValue = .dictionary(["a":.integer(1),"b":.integer(4)])
        XCTAssertEqual(try DraftRebase.merge(base:base,draft:draft,current:current),.dictionary(["a":.integer(3),"b":.integer(4)]))
        XCTAssertEqual(try DraftRebase.merge(base:base,draft:draft,current:draft),draft)
        XCTAssertThrowsError(try DraftRebase.merge(base:base,draft:draft,current:.dictionary(["a":.integer(5),"b":.integer(2)])))
        XCTAssertEqual(draft.value(at:["a"]),.integer(3))
    }
}
