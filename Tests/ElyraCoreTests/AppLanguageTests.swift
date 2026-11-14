// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore

final class AppLanguageTests: XCTestCase {
    func testExplicitLanguageOverridesTheSystem() {
        XCTAssertEqual(AppLanguage.english.resolvedCode(preferredLanguages: ["zh-Hans-CN"]), "en")
        XCTAssertEqual(AppLanguage.simplifiedChinese.resolvedCode(preferredLanguages: ["en-US"]), "zh-Hans")
    }
    func testFollowSystemUsesFirstSupportedPreferenceAndEnglishFallback() {
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["fr-FR", "zh-Hans-CN", "en-US"]), "zh-Hans")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["en-GB", "zh-Hans"]), "en")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["zh_CN"]), "zh-Hans")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: ["ja-JP"]), "en")
        XCTAssertEqual(AppLanguage.system.resolvedCode(preferredLanguages: []), "en")
    }
    func testMissingAndUnknownPreferencesSafelyFollowSystem() {
        XCTAssertEqual(AppLanguage(preference: nil), .system)
        XCTAssertEqual(AppLanguage(preference: "unsupported"), .system)
        XCTAssertEqual(AppLanguage(preference: "zh-Hans"), .simplifiedChinese)
    }
}
