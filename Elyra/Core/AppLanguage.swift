// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, english = "en", simplifiedChinese = "zh-Hans"
    public var id: String { rawValue }
    public init(preference: String?) { self = preference.flatMap(Self.init(rawValue:)) ?? .system }
    public func resolvedCode(preferredLanguages: [String]) -> String {
        guard self == .system else { return rawValue }
        for language in preferredLanguages {
            let code = language.replacingOccurrences(of: "_", with: "-").lowercased()
            if code == "zh" || code.hasPrefix("zh-") { return "zh-Hans" }
            if code == "en" || code.hasPrefix("en-") { return "en" }
        }
        return "en"
    }
}
