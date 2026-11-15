// SPDX-License-Identifier: GPL-3.0-only
import Foundation

/// Display preferences and a bounded recipe. Hardware identity is unchanged.
public enum DevicePreferenceRecipe: Equatable, Sendable {
    case intelligenceMainland, restoreIntelligence, modelName(String), restoreModelName, regionCode(String), restoreRegionCode
    var restoresCapturedValues: Bool {
        switch self {
        case .restoreIntelligence, .restoreModelName, .restoreRegionCode: true
        default: false
        }
    }
}
public struct DevicePreferencePlan: Identifiable, Sendable {
    public let id: UUID
    public let recipe: DevicePreferenceRecipe
    public let snapshot: SystemSnapshot
    public let target: PlistValue
    public var changes: [PlistChange] { PlistChange.between(snapshot.value, target) }
}
public enum DevicePreferences {
    public static let regionCode = "h63QSdBCiT/z0WU6rdQv6Q"
    /// Raw codes from the pinned upstream RegionPreset catalog. Sales suffixes
    /// are separate fields; these codes do not establish service eligibility.
    public static let regionCodes = ["LL", "ZA", "J", "CH", "TA", "B", "C"]
    public static func currentRegionCode(in value: PlistValue?) -> String? {
        if case .string(let code)? = value?.value(at: ["CacheExtra", regionCode]) { return code }
        return nil
    }
    public static let modelNameKeys = ["Z/dqyWS6OZTRy10UcmUAhw", "bbtR9jQx50Fv5Af/affNtA"]
    public static let namePath = ["CacheExtra", DynamicIslandEngine.artworkKey, "ArtworkDeviceProductDescription"]
    public static let mutableKeys = Set(modelNameKeys + [regionCode])
    public static let intelligence = Capability.all.filter { $0.category == "intelligence" && $0.id != "siriOnDevice" }
    public static var intelligencePaths: [[String]] { intelligence.flatMap { $0.keys.map { ["CacheExtra", $0] } } + [["CacheExtra", regionCode]] }
    public static var modelNamePaths: [[String]] { [namePath] + modelNameKeys.map { ["CacheExtra", $0] } }
    public static func modelName(in value: PlistValue) -> String? {
        for path in modelNamePaths { if case .string(let name)? = value.value(at: path) { return name } }
        return nil
    }
    public static func applying(_ recipe: DevicePreferenceRecipe, to value: PlistValue, original: PlistValue? = nil) throws -> PlistValue {
        guard case .dictionary? = value.value(at: ["CacheExtra"]) else { throw ElyraError.invalid("This document has no CacheExtra dictionary.") }
        var target = value
        switch recipe {
        case .intelligenceMainland:
            for feature in intelligence { try feature.stage(in: &target) }
            // GestaltX separates this code from the sales suffix; preserve both suffixes.
            try target.set(.string("LL"), at: ["CacheExtra", regionCode])
        case .modelName(let input):
            let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.utf8.count <= 256, !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { throw ElyraError.invalid("Enter a model name of 1–256 bytes without control characters.") }
            if target.value(at: ["CacheExtra", DynamicIslandEngine.artworkKey]) == nil { try target.set(.dictionary([:]), at: ["CacheExtra", DynamicIslandEngine.artworkKey]) }
            for path in modelNamePaths { try target.set(.string(name), at: path) }
        case .regionCode(let code):
            guard regionCodes.contains(code) else { throw ElyraError.invalid("Choose a supported region code.") }
            try target.set(.string(code), at: ["CacheExtra", regionCode])
        case .restoreIntelligence, .restoreModelName, .restoreRegionCode:
            guard let original else { throw ElyraError.invalid("No verified initial device capture is available for this cache generation.") }
            let paths = recipe == .restoreIntelligence ? intelligencePaths : recipe == .restoreModelName ? modelNamePaths : [["CacheExtra", regionCode]]
            for path in paths {
                let recorded = original.value(at: path)
                if path == namePath, target.value(at: ["CacheExtra", DynamicIslandEngine.artworkKey]) == nil {
                    if recorded == nil { continue }
                    try target.set(.dictionary([:]), at: ["CacheExtra", DynamicIslandEngine.artworkKey])
                }
                try target.set(recorded, at: path)
            }
            if recipe == .restoreModelName, case .dictionary(let members)? = target.value(at: ["CacheExtra", DynamicIslandEngine.artworkKey]), members.isEmpty, original.value(at: ["CacheExtra", DynamicIslandEngine.artworkKey]) == nil {
                try target.set(nil, at: ["CacheExtra", DynamicIslandEngine.artworkKey])
            }
        }
        return target
    }
}
public enum CapabilityState: String, Sendable {
    case enabled = "Enabled", disabled = "Disabled", mixed = "Partially enabled", unread = "Not read yet", unknown = "Unverified value"
}
extension Capability {
    public func state(in document: PlistValue?) -> CapabilityState {
        guard let document else { return .unread }
        let states: [CapabilityState] = keys.map { key in
            guard let current = document.value(at: ["CacheExtra", key]) else { return .disabled }
            if id == "ipadApps" {
                guard case .array(let values) = current else { return .unknown }
                return values.contains(.integer(2)) ? .enabled : .disabled
            }
            let number: Int64
            switch current { case .boolean(let flag): number = flag ? 1 : 0; case .integer(let n): number = n; default: return .unknown }
            guard number >= 0 else { return .unknown }
            if id == "siriAIMode" { return number == 2 ? .enabled : .disabled }
            return (value == 0 ? number == 0 : number > 0) ? .enabled : .disabled
        }
        if states.contains(.unknown) { return .unknown }
        if states.allSatisfy({ $0 == .enabled }) { return .enabled }
        if states.allSatisfy({ $0 == .disabled }) { return .disabled }
        return .mixed
    }
    public func stageDisabled(in document: inout PlistValue) throws {
        guard id != "siriOnDevice" else { throw ElyraError.invalid("On-Device Siri has a device-specific type. Restore a recorded original instead of guessing.") }
        guard case .dictionary? = document.value(at: ["CacheExtra"]) else { throw ElyraError.invalid("This document has no CacheExtra dictionary.") }
        for key in keys {
            let number: Int64 = value == 0 ? 1 : 0
            let target: PlistValue
            if id == "ipadApps" { target = .array([.integer(1)]) }
            else if case .boolean? = document.value(at: ["CacheExtra", key]) { target = .boolean(number != 0) }
            else { target = .integer(number) }
            try document.set(target, at: ["CacheExtra", key])
        }
    }
}
