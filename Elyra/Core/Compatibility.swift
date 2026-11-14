// SPDX-License-Identifier: GPL-3.0-only
import Foundation
public enum SupportStatus: String, Codable, CaseIterable, Sendable {
    case supported = "Supported", partial = "Partial support", experimental = "Experimental"
    case needsConditions = "Additional conditions required", unsupportedOS = "Unsupported system"
    case unsupportedHardware = "Unsupported hardware", unverified = "Unverified"
}
public struct CompatibilityReport: Sendable {
    public let ui: SupportStatus
    public let localFiles: SupportStatus
    public let systemRead: SupportStatus
    public let systemWrite: SupportStatus
    public let visualEffect: SupportStatus
    public let reason: String
}
public enum CompatibilityEngine {
    /// Never equate a major version, model, or readable file with an authorized system writer.
    public static func report(version: OperatingSystemVersion) -> CompatibilityReport {
        CompatibilityReport(ui: version.majorVersion >= 17 ? .unverified : .unsupportedOS,
                            localFiles: .partial, systemRead: .needsConditions, systemWrite: .needsConditions,
                            visualEffect: .unverified,
                            reason: "No authorized, verified system writer is installed. Imported plists remain local documents. OS build and hardware effects require separate real-device validation.")
    }
}
public enum WindowLayout: String, Sendable {
    case compact, medium, wide
    public static func resolve(width: Double, height: Double, accessibilityText: Bool = false) -> Self {
        if accessibilityText || width < 720 || height < 360 { return .compact }
        return width < 1100 ? .medium : .wide
    }
}
