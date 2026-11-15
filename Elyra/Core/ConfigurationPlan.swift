// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public struct SystemBackupInspection: Sendable {
    public let record: SystemBackup
    public let data: Data
    public let value: PlistValue
}
public struct ConfigurationStep: Codable, Equatable, Sendable {
    public enum Action: String, Codable, Hashable, Sendable { case apply, restore }
    public let capabilityID: String
    public let action: Action
    public init(capabilityID: String, action: Action) { self.capabilityID = capabilityID; self.action = action }
}
public struct ConfigurationPlan: Codable, Identifiable, Equatable, Sendable {
    public let schemaVersion: Int
    public let id: UUID
    public let name: String
    public let steps: [ConfigurationStep]
    public static let maximumBytes = 64 * 1024
    public init(name: String, steps: [ConfigurationStep], id: UUID = UUID()) {
        schemaVersion = 1; self.id = id; self.name = name.trimmingCharacters(in: .whitespacesAndNewlines); self.steps = steps
    }
    public func validate() throws {
        guard schemaVersion == 1 else { throw ElyraError.invalid("This configuration plan uses an unsupported format.") }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.utf8.count <= 256,
              !steps.isEmpty, steps.count <= Capability.all.count else { throw ElyraError.invalid("Enter a plan name and select at least one feature.") }
        guard Set(steps.map(\.capabilityID)).count == steps.count else { throw ElyraError.invalid("A configuration plan cannot contain the same feature twice.") }
        for step in steps {
            guard Capability.all.contains(where: { $0.id == step.capabilityID }), !(step.capabilityID == "siriOnDevice" && step.action == .apply) else { throw ElyraError.invalid("This plan contains an unsupported feature or action.") }
        }
    }
    public func encoded() throws -> Data {
        try validate(); let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(self)
        guard data.count <= Self.maximumBytes else { throw ElyraError.invalid("Configuration plan exceeds 64 KB.") }; return data
    }
    public static func imported(_ data: Data) throws -> Self {
        guard data.count <= maximumBytes else { throw ElyraError.invalid("Configuration plan exceeds 64 KB.") }
        let original = try JSONDecoder().decode(Self.self, from: data); try original.validate()
        return Self(name: original.name, steps: original.steps) // imports never overwrite an existing plan ID
    }
}
public struct SystemConfigurationPlan: Identifiable, Sendable {
    public let id: UUID
    public let plan: ConfigurationPlan
    public let snapshot: SystemSnapshot
    public let target: PlistValue
    public var changes: [PlistChange] { PlistChange.between(snapshot.value, target) }
}
extension Workspace {
    private var plansDirectory: URL { root.appendingPathComponent("ConfigurationPlans", isDirectory: true) }
    public func configurationPlans() throws -> [ConfigurationPlan] {
        guard FileManager.default.fileExists(atPath: plansDirectory.path) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(at: plansDirectory, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]).filter { $0.pathExtension == "json" }
        guard files.count <= 100 else { throw ElyraError.invalid("The configuration plan limit is 100.") }
        return try files.map { url in
            let metadata = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard metadata.isRegularFile == true, metadata.isSymbolicLink != true, let size = metadata.fileSize, size <= ConfigurationPlan.maximumBytes else { throw ElyraError.integrity }
            let plan = try JSONDecoder().decode(ConfigurationPlan.self, from: Data(contentsOf: url)); try plan.validate()
            guard url.deletingPathExtension().lastPathComponent == plan.id.uuidString else { throw ElyraError.integrity }; return plan
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    public func saveConfigurationPlan(_ plan: ConfigurationPlan, replacing expected: ConfigurationPlan? = nil) throws {
        let data = try plan.encoded(); let existing = try configurationPlans()
        if let stored = existing.first(where: { $0.id == plan.id }) {
            guard let expected, stored == expected else { throw ElyraError.conflict }
        } else if expected != nil { throw ElyraError.conflict }
        guard existing.count < 100 || existing.contains(where: { $0.id == plan.id }) else { throw ElyraError.invalid("The configuration plan limit is 100.") }
        try FileManager.default.createDirectory(at: plansDirectory, withIntermediateDirectories: true)
        let url = plansDirectory.appendingPathComponent(plan.id.uuidString + ".json")
        try data.write(to: url, options: .atomic)
        guard try Data(contentsOf: url) == data else { throw ElyraError.integrity }
    }
    public func deleteConfigurationPlan(_ id: UUID) throws { try FileManager.default.removeItem(at: plansDirectory.appendingPathComponent(id.uuidString + ".json")) }
}
public enum DraftRebase {
    public static func merge(base: PlistValue, draft: PlistValue, current: PlistValue) throws -> PlistValue {
        let edits = PlistChange.between(base, draft), external = PlistChange.between(base, current)
        var merged = current
        for change in edits {
            if current.value(at: change.path) == change.after { continue }
            guard !external.contains(where: { $0.path.starts(with: change.path) || change.path.starts(with: $0.path) }) else { throw ElyraError.conflict }
            try merged.set(change.after, at: change.path)
        }
        return merged
    }
}
