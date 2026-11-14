// SPDX-License-Identifier: GPL-3.0-only
import XCTest

final class ElyraUITests: XCTestCase {
    @MainActor private func makeApp(chineseAccessibility: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ElyraTestWorkspace", UUID().uuidString]
        if chineseAccessibility {
            app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans_CN",
                                    "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        } else { app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"] }
        XCUIDevice.shared.orientation = .portrait
        return app
    }
    @MainActor private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Expected control must remain reachable by scrolling")
    }
    @MainActor private func openLab(_ app: XCUIApplication) {
        let link = app.descendants(matching: .any)["home.island"].firstMatch
        reveal(link, app: app)
        link.tap()
        let title = app.launchArguments.contains("(zh-Hans)") ? "Dynamic Island Lab · 灵动岛实验室" : "Dynamic Island Lab"
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
    }
    @MainActor func testLaunchNavigationAndRotation() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Local workspace is ready"].waitForExistence(timeout: 10))
        attach("Portrait launch")
        openLab(app)
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        attach("Landscape lab")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        attach("Portrait lab after rotation")
    }
    @MainActor func testObservationPersistsAcrossRelaunchWithoutBeingSystemProof() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Local workspace is ready"].waitForExistence(timeout: 10))
        openLab(app)
        let record = app.buttons["island.record"]
        reveal(record, app: app); record.tap()
        XCTAssertTrue(app.buttons["island.observation.save"].waitForExistence(timeout: 5))
        let notes = app.textViews["island.observation.notes"]
        reveal(notes, app: app); notes.tap(); notes.typeText("UI observation; simulator only.")
        app.buttons["island.observation.save"].tap()
        XCTAssertTrue(app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5))
        attach("Recorded simulator observation")
        app.terminate(); app.launch()
        if !app.navigationBars["Dynamic Island Lab"].waitForExistence(timeout: 5) { openLab(app) }
        let entry = app.staticTexts["Simulator observation"].firstMatch
        reveal(entry, app: app)
        XCTAssertTrue(entry.exists)
    }
    @MainActor func testChineseAccessibilityTextKeepsNavigationReachable() {
        let app = makeApp(chineseAccessibility: true); app.launch()
        XCTAssertTrue(app.staticTexts["本地工作区已就绪"].waitForExistence(timeout: 10))
        attach("Chinese accessibility launch")
        openLab(app)
        let record = app.buttons["island.record"]
        reveal(record, app: app)
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(record.frame.minX, window.minX - 1)
        XCTAssertLessThanOrEqual(record.frame.maxX, window.maxX + 1)
        attach("Chinese accessibility lab")
    }
    @MainActor private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
