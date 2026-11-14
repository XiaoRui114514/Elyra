// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

@MainActor final class LocalizationStore: ObservableObject {
    private let defaults: UserDefaults
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "elyra.language") }
    }
    init() {
        var selectedDefaults = UserDefaults.standard
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-ElyraTestWorkspace"), args.indices.contains(index + 1),
           let id = UUID(uuidString: args[index + 1]),
           let isolated = UserDefaults(suiteName: "org.elyra.UITests." + id.uuidString) {
            selectedDefaults = isolated
        }
        #endif
        defaults = selectedDefaults
        language = AppLanguage(preference: selectedDefaults.string(forKey: "elyra.language"))
    }
    var code: String { language.resolvedCode(preferredLanguages: Locale.preferredLanguages) }
    var locale: Locale { Locale(identifier: code) }
    private var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
    func text(_ key: String) -> String { bundle.localizedString(forKey: key, value: key, table: nil) }
    func backupReason(_ reason: String) -> String {
        guard reason.hasPrefix("Before ") else { return text(reason) }
        return String(format: text("Before operation: %@"), locale: locale,
                      arguments: [text(String(reason.dropFirst("Before ".count)))])
    }
    func bytes(_ count: Int64, memory: Bool = false) -> String {
        count.formatted(.byteCount(style: memory ? .memory : .file).locale(locale))
    }
}
