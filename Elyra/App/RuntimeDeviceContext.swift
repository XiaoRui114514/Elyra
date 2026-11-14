// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import Darwin

struct RuntimeDeviceContext: Sendable {
    let hardware: String
    let osVersion: String
    let build: String
    let simulator: Bool
    static var current: Self {
        #if targetEnvironment(simulator)
        let simulator = true
        let hardware = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
        let simulator = false
        let hardware = readSysctl("hw.machine")
        #endif
        return Self(hardware: hardware, osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                    build: readSysctl("kern.osversion"), simulator: simulator)
    }
    private static func readSysctl(_ key: String) -> String {
        var size = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return "Unavailable" }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return "Unavailable" }
        return String(cString: buffer)
    }
}
