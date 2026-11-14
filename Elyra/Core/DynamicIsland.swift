// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public enum IslandFlag: String, Codable, Sendable {
    case enabled = "Enabled flag", disabled = "Disabled flag", absent = "Absent", invalid = "Unexpected type or value"
}
public struct IslandInspection: Sendable, Equatable {
    public let flag: IslandFlag
    public let rawFlag: PlistValue?
    public let rawSubtype: PlistValue?
    public let artworkIsValid: Bool
    public let isIPad: Bool
    public let usesPhoneArtwork: Bool
    public var subtype: Int64? {
        guard case .integer(let value) = rawSubtype else { return nil }
        return value
    }
}
public enum IslandAction: String, CaseIterable, Identifiable, Sendable {
    case enableFlag = "Enable capability in local copy"
    case restoreBaseline = "Restore recorded DI fields"
    public var id: String { rawValue }
}
public struct IslandPlan: Identifiable, Sendable {
    public let id = UUID()
    public let action: IslandAction
    public let snapshot: DocumentSnapshot
    public let target: PlistValue
    public let baseline: BackupRecord?
    public var changes: [PlistChange] { PlistChange.between(snapshot.value, target) }
}
public enum DynamicIslandEngine {
    public static let flagKey = "YlEtTtHlNesRBMal1CqRaA"
    public static let artworkKey = "oPeik/9e8lQWMszEjbPzng"
    public static let subtypeKey = "ArtworkDeviceSubType"
    // Source catalog identifiers, not dimensions or validated iPad repair values.
    public static let phoneSubtypes: Set<Int64> = [2436, 2556, 2796, 2976, 2736, 2622, 2868, 2670]

    public static func inspect(_ value: PlistValue, physicalHardware: String) throws -> IslandInspection {
        guard case .dictionary(let extra) = value.value(at: ["CacheExtra"]) else {
            throw ElyraError.invalid("This document has no CacheExtra dictionary.")
        }
        let rawFlag = extra[flagKey]
        let flag: IslandFlag
        switch rawFlag {
        case nil: flag = .absent
        case .boolean(true)?, .integer(1)?: flag = .enabled
        case .boolean(false)?, .integer(0)?: flag = .disabled
        default: flag = .invalid
        }
        let artwork = extra[artworkKey]
        let artworkValid: Bool
        if case .dictionary = artwork { artworkValid = true } else { artworkValid = artwork == nil }
        let subtype = value.value(at: ["CacheExtra", artworkKey, subtypeKey])
        let phone: Bool
        if case .integer(let number) = subtype { phone = phoneSubtypes.contains(number) } else { phone = false }
        return IslandInspection(flag: flag, rawFlag: rawFlag, rawSubtype: subtype,
                                artworkIsValid: artworkValid, isIPad: physicalHardware.hasPrefix("iPad"), usesPhoneArtwork: phone)
    }
    public static func enablingFlag(in value: PlistValue) throws -> PlistValue {
        let inspection = try inspect(value, physicalHardware: "")
        guard inspection.artworkIsValid, inspection.flag != .invalid else {
            throw ElyraError.invalid("Unexpected Dynamic Island field types. Inspect the plist before staging a preset.")
        }
        var target = value
        // Preserve an already enabled Boolean rather than coercing it to Integer.
        if inspection.flag != .enabled { try target.set(.integer(1), at: ["CacheExtra", flagKey]) }
        return target
    }
    public static func restoringRecordedFields(in value: PlistValue, baseline: PlistValue) throws -> PlistValue {
        let current = try inspect(value, physicalHardware: "")
        let original = try inspect(baseline, physicalHardware: "")
        guard current.artworkIsValid, original.artworkIsValid else {
            throw ElyraError.invalid("ArtworkTraits is not a dictionary. No fields were restored.")
        }
        // Local lineage is checked by Workspace. These checks also reject cache-generation drift.
        for key in ["CacheUUID", "CacheVersion"] {
            let a = value.value(at: [key]), b = baseline.value(at: [key])
            if key == "CacheUUID", case .string(let left)? = a, case .string(let right)? = b {
                guard left.caseInsensitiveCompare(right) == .orderedSame else { throw ElyraError.invalid("The baseline uses a different cache generation.") }
            } else if a != b { throw ElyraError.invalid("The baseline uses a different cache generation.") }
        }
        switch (value.value(at: ["CacheData"]), baseline.value(at: ["CacheData"])) {
        case (nil, nil): break
        case (.data(let a)?, .data(let b)?) where a.count == b.count: break
        default: throw ElyraError.invalid("The baseline uses a different cache generation.")
        }
        var target = value
        try target.set(original.rawFlag, at: ["CacheExtra", flagKey])
        let artworkPath = ["CacheExtra", artworkKey]
        var members: [String: PlistValue]
        if case .dictionary(let existing)? = target.value(at: artworkPath) { members = existing } else { members = [:] }
        members[subtypeKey] = original.rawSubtype
        // Restore only this member; keep model-name/custom artwork edits and exact absence semantics.
        if members.isEmpty, baseline.value(at: artworkPath) == nil { try target.set(nil, at: artworkPath) }
        else { try target.set(.dictionary(members), at: artworkPath) }
        return target
    }
}
public enum IslandActivity: String, Codable, CaseIterable, Identifiable, Sendable {
    case idle = "Idle", compact = "Compact music", expanded = "Expanded music", multiple = "Multiple activities"
    case recording = "Screen recording", timer = "Timer", call = "Call", navigation = "Navigation", other = "Other activity"
    public var id: String { rawValue }
    public var canIncludeMedia: Bool { self == .compact || self == .expanded || self == .multiple }
}
public enum IslandOrientation: String, Codable, CaseIterable, Identifiable, Sendable {
    case portrait = "Portrait", landscape = "Landscape"
    public var id: String { rawValue }
}
public enum IslandOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case tall = "Tall media region", normal = "Expected appearance", missing = "Activity not visible", keyboard = "Keyboard issue", other = "Other / uncertain"
    case corners = "Corners insufficiently rounded", proportions = "Unexpected shape or proportions", position = "Unexpected position"
    public var id: String { rawValue }
}
public struct IslandObservation: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let hardware: String
    public let osVersion: String
    public let build: String
    public let simulator: Bool
    public let activity: IslandActivity
    public let orientation: IslandOrientation
    public let playing: Bool?
    public let outcome: IslandOutcome
    public let notes: String
    public let documentID: UUID?
    public let documentRevision: String?
    public init(hardware: String, osVersion: String, build: String, simulator: Bool,
                activity: IslandActivity, orientation: IslandOrientation, playing: Bool?,
                outcome: IslandOutcome, notes: String, documentID: UUID? = nil, documentRevision: String? = nil) {
        id = UUID(); date = Date(); self.hardware = hardware; self.osVersion = osVersion; self.build = build
        self.simulator = simulator; self.activity = activity; self.orientation = orientation; self.playing = playing
        self.outcome = outcome; self.notes = notes; self.documentID = documentID; self.documentRevision = documentRevision
    }
}
