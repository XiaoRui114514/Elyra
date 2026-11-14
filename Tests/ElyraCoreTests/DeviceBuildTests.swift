// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore

final class DeviceBuildTests: XCTestCase {
    func testSimulatorUsesRuntimeBuildInsteadOfHostKernel() {
        XCTAssertEqual(DeviceBuildIdentification.build(simulator: true, environmentBuild: nil,
                                                       versionDescription: "Version 26.2 (Build 23C54)", kernelBuild: "24H232"), "23C54")
    }
    func testSimulatorEnvironmentIsValidatedAndPreferred() {
        XCTAssertEqual(DeviceBuildIdentification.build(simulator: true, environmentBuild: "24A5320a",
                                                       versionDescription: "Version 27 (Build 24A10)", kernelBuild: "24H232"), "24A5320a")
        XCTAssertEqual(DeviceBuildIdentification.build(simulator: true, environmentBuild: "not-a-build",
                                                       versionDescription: "Version 26.2 (Build 23C54)", kernelBuild: "24H232"), "23C54")
    }
    func testSimulatorNeverFallsBackToMacOSBuildWhenRuntimeIsUnknown() {
        XCTAssertNil(DeviceBuildIdentification.build(simulator: true, environmentBuild: nil,
                                                      versionDescription: "Unknown simulator", kernelBuild: "24H232"))
    }
    func testPhysicalDeviceUsesItsKernelBuildWithoutGuessing() {
        XCTAssertEqual(DeviceBuildIdentification.build(simulator: false, environmentBuild: "23C54",
                                                       versionDescription: "Unknown", kernelBuild: "24A5320a"), "24A5320a")
        XCTAssertNil(DeviceBuildIdentification.build(simulator: false, environmentBuild: "23C54", versionDescription: "Unknown", kernelBuild: "Unavailable"))
        XCTAssertNil(DeviceBuildIdentification.build(simulator: false, environmentBuild: nil, versionDescription: "Unknown", kernelBuild: "23C54\n"))
    }
}
