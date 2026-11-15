// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public enum Screen: Hashable, Codable, Sendable {
    case document(UUID), field(UUID, [String]), islandDocument(UUID), textAsset(UUID), archive(UUID), capability(String), island, category(String), files, backups, diagnostics, history, licenses, language, device, systemEditor(UUID), openSource, deviceBackup(UUID), plans, displayDiagnostics, intelligenceSetup, modelName, regionCode
}
public enum Area: String, CaseIterable, Codable, Sendable {
    case home = "Home", appearance = "Appearance", system = "System", tools = "Tools", settings = "Settings"
    public var symbol: String {
        switch self {
        case .home: "house"
        case .appearance: "paintpalette"
        case .system: "switch.2"
        case .tools: "wrench.and.screwdriver"
        case .settings: "gearshape"
        }
    }
}
/// Each scene owns this value; switching areas never reuses another area's stack.
public struct SceneNavigation: Codable, Equatable, Sendable {
    private var paths: [String: [Screen]] = [:]
    public init() {}
    public func path(for area: Area) -> [Screen] { paths[area.rawValue] ?? [] }
    public mutating func setPath(_ path: [Screen], for area: Area) { paths[area.rawValue] = path }
    public static func restored(_ data: Data?, legacy: Data?, area: Area) -> Self {
        if let data, let saved = try? JSONDecoder().decode(Self.self, from: data) { return saved }
        var state = Self()
        if let legacy, let path = try? JSONDecoder().decode([Screen].self, from: legacy) { state.setPath(path, for: area) }
        return state
    }
}
public enum DeviceAccessState: String, Sendable {
    case unchecked = "Access not checked"
    case checking = "Checking device access…"
    case readWrite = "Read and write access"
    case readOnly = "Read-only access"
    case failed = "Device access failed"
    case recovery = "System recovery required"
    case simulator = "Simulator"
    public static func resolve(simulator: Bool, checking: Bool, readable: Bool, writable: Bool, failed: Bool, recovery: Bool) -> Self {
        if simulator { return .simulator }
        if recovery { return .recovery }
        if checking { return .checking }
        if readable { return writable ? .readWrite : .readOnly }
        return failed ? .failed : .unchecked
    }
}
