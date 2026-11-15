// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public protocol SystemConfigurationFile: Sendable {
    var identity: String { get }
    func read() throws -> Data
    func replace(_ data: Data) throws
    func close()
}
public struct SystemAccess: Sendable {
    public let open: @Sendable (Bool) throws -> any SystemConfigurationFile
    public init(open: @escaping @Sendable (Bool) throws -> any SystemConfigurationFile) { self.open = open }
}
public struct SystemSnapshot: Sendable {
    public let id: UUID
    public let fileIdentity: String
    public let data: Data
    public let value: PlistValue
    public let writable: Bool
    public let accessError: String?
    public var revision: String { Digest.sha256(data) }
}
public struct SystemBackup: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let digest: String
    public let generation: String
    public let binding: String
    public let reason: String
    public var generationVersion: Int? = nil
    public var filename: String { id.uuidString + ".plist" }
}
public struct SystemCapabilityPlan: Identifiable, Sendable {
    public let id: UUID
    public let capabilityID: String
    public let restoring: Bool
    public let disabling: Bool
    public let snapshot: SystemSnapshot
    public let target: PlistValue
    public var changes: [PlistChange] { PlistChange.between(snapshot.value, target) }
}
private struct SystemJournal: Codable {
    let backup: UUID
    let fileIdentity: String
    let expected: String
    let desired: String
}
public enum SystemEditPolicy {
    private static var keys: Set<String> { Set(Capability.all.flatMap(\.keys)) }
    public static func generation(_ value: PlistValue, version: Int = 2) throws -> String {
        guard [1, 2].contains(version) else { throw ElyraError.integrity }
        guard case .dictionary = value, case .dictionary(var extra)? = value.value(at: ["CacheExtra"]) else {
            throw ElyraError.invalid("The device cache has an unsupported structure.")
        }
        for key in keys { extra.removeValue(forKey: key) }
        if version == 2 { for key in DevicePreferences.mutableKeys { extra.removeValue(forKey: key) } }
        if case .dictionary(var artwork)? = extra[DynamicIslandEngine.artworkKey] {
            artwork.removeValue(forKey: DynamicIslandEngine.subtypeKey)
            artwork.removeValue(forKey: "ArtworkDeviceProductDescription")
            extra[DynamicIslandEngine.artworkKey] = artwork.isEmpty ? nil : .dictionary(artwork)
        }
        var stable = value; try stable.set(.dictionary(extra), at: ["CacheExtra"])
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return Digest.sha256(try encoder.encode(stable))
    }
    public static func validate(_ target: PlistValue, from original: PlistValue, restoring: Bool = false) throws {
        guard try generation(target) == generation(original) else {
            throw ElyraError.invalid("Only supported capability and artwork fields can be written. Device identity and binary cache changes are protected.")
        }
        guard !restoring else { return }
        for change in PlistChange.between(original, target) {
            guard let after = change.after else { continue }
            if change.path == ["CacheExtra", DynamicIslandEngine.artworkKey, "ArtworkDeviceProductDescription"] {
                guard case .string(let text) = after, text.utf8.count <= 256 else { throw ElyraError.invalid("Enter a device display name under 256 bytes.") }; continue
            }
            if change.path == ["CacheExtra", DynamicIslandEngine.artworkKey, DynamicIslandEngine.subtypeKey] {
                guard case .integer(let number) = after, [2436,2556,2796,2736,2622,2868].contains(number) else {
                    throw ElyraError.invalid("Choose a documented artwork subtype. This does not verify its appearance on this device.")
                }; continue
            }
            // Adding an artwork dictionary is checked member by member.
            if change.path == ["CacheExtra", DynamicIslandEngine.artworkKey], case .dictionary(let members) = after {
                for (key, value) in members {
                    if key == "ArtworkDeviceProductDescription", case .string(let name) = value, name.utf8.count <= 256 { continue }
                    if key == DynamicIslandEngine.subtypeKey, case .integer(let n) = value, [2436,2556,2796,2736,2622,2868].contains(n) { continue }
                    throw ElyraError.invalid("Unsupported artwork changes.")
                }; continue
            }
            if change.path.count == 2, DevicePreferences.mutableKeys.contains(change.path[1]) {
                guard case .string(let text) = after, !text.isEmpty, text.utf8.count <= 256,
                      !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
                      change.path[1] != DevicePreferences.regionCode || text == "LL" else { throw ElyraError.invalid("Unsupported device display preference.") }
                continue
            }
            guard change.path.count == 2, keys.contains(change.path[1]) else { throw ElyraError.invalid("Unsupported system field change.") }
            let matching = Capability.all.filter { $0.keys.contains(change.path[1]) }
            guard !matching.contains(where: { $0.id == "siriOnDevice" }) else { throw ElyraError.invalid("On-Device Siri has a device-specific type. Restore a recorded original instead of guessing.") }
            if matching.contains(where: { $0.id == "ipadApps" }), [PlistValue.array([.integer(1), .integer(2)]), .array([.integer(1)])].contains(after) { continue }
            let integers = Set(matching.map(\.value) + [0,1])
            switch after {
            case .boolean: break
            case .integer(let number) where integers.contains(number): break
            default: throw ElyraError.invalid("Capability values must be Boolean or a supported nonnegative integer.")
            }
        }
    }
}

/// One shared device writer. No imported document can establish a live session.
public actor SystemConfigurationStore {
    private let root: URL
    private let binding: String
    private let access: SystemAccess
    private var current: SystemSnapshot?
    private var backups: [SystemBackup]
    public init(root: URL, binding: String, access: SystemAccess) throws {
        guard !binding.isEmpty else { throw ElyraError.invalid("Device backup binding is unavailable.") }
        self.root = root; self.binding = binding; self.access = access
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let index = root.appendingPathComponent("backups.json")
        backups = FileManager.default.fileExists(atPath: index.path) ? try JSONDecoder().decode([SystemBackup].self, from: Data(contentsOf: index)) : []
    }
    private var journalURL: URL { root.appendingPathComponent("pending.json") }
    public func listing() -> [SystemBackup] { backups.filter { $0.binding == binding } }
    public func recoveryPending() -> Bool { FileManager.default.fileExists(atPath: journalURL.path) }
    private func decoded(_ data: Data) throws -> PlistValue {
        let value = try PlistValue.decode(data); _ = try SystemEditPolicy.generation(value); return value
    }
    private func capture(_ data: Data, reason: String) throws -> SystemBackup {
        let backup = SystemBackup(id: UUID(), date: Date(), digest: Digest.sha256(data), generation: try SystemEditPolicy.generation(decoded(data)), binding: binding, reason: reason, generationVersion: 2)
        let file = root.appendingPathComponent(backup.filename)
        try data.write(to: file, options: .atomic)
        guard try Data(contentsOf: file) == data else { throw ElyraError.integrity }
        let next = [backup] + backups
        try JSONEncoder().encode(next).write(to: root.appendingPathComponent("backups.json"), options: .atomic)
        backups = next
        return backup
    }
    private func backupData(_ backup: SystemBackup) throws -> Data {
        guard backup.binding == binding else { throw ElyraError.invalid("This backup belongs to a different device installation.") }
        let data = try Data(contentsOf: root.appendingPathComponent(backup.filename))
        guard Digest.sha256(data) == backup.digest else { throw ElyraError.integrity }
        guard try SystemEditPolicy.generation(decoded(data), version: backup.generationVersion ?? 1) == backup.generation else { throw ElyraError.integrity }
        return data
    }
    public func inspectedBackup(_ id: UUID) throws -> SystemBackupInspection {
        guard let record = backups.first(where: { $0.id == id }) else { throw ElyraError.integrity }
        let data = try backupData(record)
        return SystemBackupInspection(record: record, data: data, value: try decoded(data))
    }
    public func configurationPlan(_ plan: ConfigurationPlan, expected: SystemSnapshot) throws -> SystemConfigurationPlan {
        guard current?.id == expected.id, !recoveryPending() else { throw ElyraError.conflict }
        try plan.validate()
        var target = expected.value
        var intents: [[String]: PlistValue?] = [:]
        for step in plan.steps {
            let staged = try capabilityPlan(step.capabilityID, restoring: step.action == .restore, expected: expected)
            guard let capability = Capability.all.first(where: { $0.id == step.capabilityID }) else { throw ElyraError.invalid("Unknown configuration feature.") }
            var paths = capability.keys.map { ["CacheExtra", $0] }
            if step.capabilityID == "dynamicIsland", step.action == .restore { paths.append(["CacheExtra", DynamicIslandEngine.artworkKey]) }
            for path in paths {
                let desired = staged.target.value(at: path)
                if let previous = intents[path], previous != desired { throw ElyraError.invalid("The configuration plan contains conflicting changes.") }
                intents.updateValue(desired, forKey: path)
                try target.set(desired, at: path)
            }
        }
        try SystemEditPolicy.validate(target, from: expected.value, restoring: true)
        return SystemConfigurationPlan(id: UUID(), plan: plan, snapshot: expected, target: target)
    }
    public func commitConfigurationPlan(_ proposal: SystemConfigurationPlan) throws -> SystemSnapshot {
        let verified = try configurationPlan(proposal.plan, expected: proposal.snapshot)
        guard verified.target == proposal.target else { throw ElyraError.conflict }
        return try commit(encodedTarget(verified.target, expected: proposal.snapshot), expected: proposal.snapshot, reason: "Before configuration plan")
    }
    public func connect() throws -> SystemSnapshot {
        guard !recoveryPending() else { throw ElyraError.invalid("An interrupted system write requires recovery before continuing.") }
        let file = try access.open(false); defer { file.close() }
        let data = try file.read(); let value = try decoded(data)
        var writable = false; var error: String?
        do { let probe = try access.open(true); defer { probe.close() }; guard try probe.read() == data else { throw ElyraError.conflict }; writable = true }
        catch let failure { error = failure.localizedDescription }
        if try initialCapture(for: value) == nil {
            _ = try capture(data, reason: "Initial device capture")
        }
        let snapshot = SystemSnapshot(id: UUID(), fileIdentity: file.identity, data: data, value: value, writable: writable, accessError: error)
        current = snapshot; return snapshot
    }
    private func initialCapture(for value: PlistValue) throws -> SystemBackup? {
        let generation = try SystemEditPolicy.generation(value)
        for record in backups.filter({ $0.binding == binding && $0.reason == "Initial device capture" }).sorted(by: { $0.date < $1.date }) {
            if try SystemEditPolicy.generation(decoded(backupData(record))) == generation { return record }
        }
        return nil
    }
    public func preferencePlan(_ recipe: DevicePreferenceRecipe, expected: SystemSnapshot) throws -> DevicePreferencePlan {
        guard current?.id == expected.id, !recoveryPending() else { throw ElyraError.conflict }
        var baseline: PlistValue?
        if recipe == .restoreIntelligence || recipe == .restoreModelName {
            guard let original = try initialCapture(for: expected.value) else { throw ElyraError.invalid("No verified initial device capture is available for this cache generation.") }
            baseline = try decoded(backupData(original))
        }
        let target = try DevicePreferences.applying(recipe, to: expected.value, original: baseline)
        try SystemEditPolicy.validate(target, from: expected.value, restoring: baseline != nil)
        return DevicePreferencePlan(id: UUID(), recipe: recipe, snapshot: expected, target: target)
    }
    public func commitPreference(_ proposal: DevicePreferencePlan) throws -> SystemSnapshot {
        let verified = try preferencePlan(proposal.recipe, expected: proposal.snapshot)
        guard verified.target == proposal.target else { throw ElyraError.conflict }
        return try commit(encodedTarget(verified.target, expected: proposal.snapshot), expected: proposal.snapshot, reason: "Before device preference change")
    }
    public func manualBackup(expected: SystemSnapshot) throws {
        guard current?.id == expected.id, !recoveryPending() else { throw ElyraError.conflict }
        let file = try access.open(false); defer { file.close() }
        let data = try file.read()
        guard file.identity == expected.fileIdentity, Digest.sha256(data) == expected.revision else { throw ElyraError.conflict }
        _ = try capture(data, reason: "Manual device backup")
    }
    private func encodedTarget(_ target: PlistValue, expected: SystemSnapshot) throws -> Data {
        if target == expected.value { return expected.data }
        var format = PropertyListSerialization.PropertyListFormat.binary
        _ = try PropertyListSerialization.propertyList(from: expected.data, options: [], format: &format)
        return try target.encoded(format: format)
    }
    public func apply(_ edited: PlistValue, expected: SystemSnapshot) throws -> SystemSnapshot {
        try SystemEditPolicy.validate(edited, from: expected.value)
        return try commit(encodedTarget(edited, expected: expected), expected: expected, reason: "Before system write")
    }
    public func capabilityPlan(_ id: String, restoring: Bool, disabling: Bool = false, expected: SystemSnapshot) throws -> SystemCapabilityPlan {
        guard current?.id == expected.id, !recoveryPending(), let capability = Capability.all.first(where: { $0.id == id }) else { throw ElyraError.conflict }
        var target = expected.value
        if restoring {
            guard let original = try initialCapture(for: expected.value) else {
                throw ElyraError.invalid("No verified initial device capture is available for this cache generation.")
            }
            let baseline = try decoded(backupData(original))
            if id == "dynamicIsland" { target = try DynamicIslandEngine.restoringRecordedFields(in: target, baseline: baseline) }
            else { for key in capability.keys { try target.set(baseline.value(at: ["CacheExtra", key]), at: ["CacheExtra", key]) } }
        } else if disabling {
            if id == "dynamicIsland" {
                guard let original = try initialCapture(for: expected.value) else { throw ElyraError.integrity }
                target = try DynamicIslandEngine.restoringRecordedFields(in: target, baseline: decoded(backupData(original)))
            }
            try capability.stageDisabled(in: &target)
        }
        else { try capability.stage(in: &target) }
        try SystemEditPolicy.validate(target, from: expected.value, restoring: restoring || (id == "dynamicIsland" && disabling))
        return SystemCapabilityPlan(id: UUID(), capabilityID: id, restoring: restoring, disabling: disabling, snapshot: expected, target: target)
    }
    public func commitCapability(_ plan: SystemCapabilityPlan) throws -> SystemSnapshot {
        // Recompute restoration from a verified device capture; the UI cannot supply original values.
        let verified = try capabilityPlan(plan.capabilityID, restoring: plan.restoring, disabling: plan.disabling, expected: plan.snapshot)
        guard verified.target == plan.target else { throw ElyraError.conflict }
        if !plan.restoring && !(plan.disabling && plan.capabilityID == "dynamicIsland") { return try apply(verified.target, expected: plan.snapshot) }
        return try commit(encodedTarget(verified.target, expected: plan.snapshot), expected: plan.snapshot, reason: "Before capability restore")
    }
    public func restore(_ id: UUID, expected: SystemSnapshot) throws -> SystemSnapshot {
        guard let backup = backups.first(where: { $0.id == id }) else { throw ElyraError.integrity }
        let data = try backupData(backup)
        guard try SystemEditPolicy.generation(decoded(data)) == SystemEditPolicy.generation(expected.value) else { throw ElyraError.invalid("The backup does not match the current device cache generation.") }
        try SystemEditPolicy.validate(decoded(data), from: expected.value, restoring: true)
        return try commit(data, expected: expected, reason: "Before system restore")
    }
    private func commit(_ output: Data, expected: SystemSnapshot, reason: String) throws -> SystemSnapshot {
        guard !recoveryPending() else { throw ElyraError.invalid("An interrupted system write requires recovery before continuing.") }
        guard expected.writable, current?.id == expected.id else { throw ElyraError.conflict }
        let file = try access.open(true); defer { file.close() }
        let before = try file.read()
        guard file.identity == expected.fileIdentity, Digest.sha256(before) == expected.revision else { throw ElyraError.conflict }
        let value = try decoded(output)
        if before == output { return expected }
        let backup = try capture(before, reason: reason)
        let journal = SystemJournal(backup: backup.id, fileIdentity: file.identity, expected: expected.revision, desired: Digest.sha256(output))
        try JSONEncoder().encode(journal).write(to: journalURL, options: .atomic)
        var writingStarted = false
        do {
            // Recheck after local backup persistence, immediately before writing.
            guard try file.read() == before else { try FileManager.default.removeItem(at: journalURL); throw ElyraError.conflict }
            writingStarted = true
            try file.replace(output)
            guard try file.read() == output else { throw ElyraError.invalid("System readback did not match the written data.") }
        } catch {
            let originalError = error
            // Do not overwrite a concurrent external change detected before any write.
            if !writingStarted { throw originalError }
            do {
                try file.replace(before)
                guard try file.read() == before else { throw ElyraError.integrity }
                try FileManager.default.removeItem(at: journalURL)
            } catch { current = nil; throw ElyraError.invalid("System write and rollback failed. Keep the device backup and run recovery before further changes.") }
            throw originalError
        }
        do { try FileManager.default.removeItem(at: journalURL) }
        catch {
            current = nil
            throw ElyraError.invalid("The system write was verified, but its recovery journal could not be cleared. Run recovery before further changes.")
        }
        let saved = SystemSnapshot(id: UUID(), fileIdentity: file.identity, data: output, value: value, writable: true, accessError: nil)
        current = saved; return saved
    }
    public func recoverInterruptedWrite() throws {
        guard recoveryPending() else { return }
        let journal = try JSONDecoder().decode(SystemJournal.self, from: Data(contentsOf: journalURL))
        guard let backup = backups.first(where: { $0.id == journal.backup }) else { throw ElyraError.integrity }
        let original = try backupData(backup)
        guard Digest.sha256(original) == journal.expected else { throw ElyraError.integrity }
        let file = try access.open(true); defer { file.close() }
        guard file.identity == journal.fileIdentity else { throw ElyraError.invalid("The system cache was replaced. Automatic recovery was not started.") }
        let actual = try file.read()
        if Digest.sha256(actual) != journal.expected && Digest.sha256(actual) != journal.desired {
            if (try? decoded(actual)) != nil { throw ElyraError.invalid("The system file contains another valid change. Recovery was stopped to preserve it.") }
            // Retain the interrupted bytes before replacing a partial or corrupt write.
            let evidence = root.appendingPathComponent("recovery-" + UUID().uuidString + ".bin")
            try actual.write(to: evidence, options: .atomic)
            guard try Data(contentsOf: evidence) == actual else { throw ElyraError.integrity }
        }
        // Recovery always returns to the verified pre-write bytes, including a partial write.
        if actual != original { try file.replace(original) }
        guard try file.read() == original else { throw ElyraError.integrity }
        try FileManager.default.removeItem(at: journalURL); current = nil
    }
}
