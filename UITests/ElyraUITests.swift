// SPDX-License-Identifier: GPL-3.0-only
import XCTest

final class ElyraUITests: XCTestCase {
    @MainActor func testLaunchNavigationAndRotation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.staticTexts["Local workspace is ready"].waitForExistence(timeout: 10))
        attach("Portrait launch")
        let lab = app.buttons["Dynamic Island Lab"].firstMatch
        if lab.exists { lab.tap() }
        else { app.staticTexts["Dynamic Island Lab"].firstMatch.tap() }
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        attach("Landscape lab")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        attach("Portrait lab after rotation")
    }
    @MainActor private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
