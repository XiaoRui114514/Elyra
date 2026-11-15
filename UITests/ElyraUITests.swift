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
        // A returned page can retain an offset below the next control. Search
        // both directions; never tap a hidden element or skip reachability.
        for direction in [true, false] {
            for _ in 0..<(direction ? 8 : 16) {
                if element.exists && element.isHittable { return }
                if direction { app.swipeUp() } else { app.swipeDown() }
            }
        }
        XCTAssertTrue(element.isHittable, "Expected control must remain reachable by scrolling")
    }
    @MainActor private func openLab(_ app: XCUIApplication, expectedTitle: String? = nil) {
        let chinese = expectedTitle == "灵动岛" || app.launchArguments.contains("(zh-Hans)")
        selectArea(app, identifier: "system", title: chinese ? "系统" : "System")
        let display = app.buttons["system.category.display"].firstMatch
        reveal(display, app: app); display.tap()
        let feature = app.buttons["system.feature.dynamicIsland"].firstMatch
        reveal(feature, app: app); feature.tap()
        let lab = app.buttons["dynamicIsland.lab"].firstMatch
        reveal(lab, app: app); lab.tap()
        let title = expectedTitle ?? (app.launchArguments.contains("(zh-Hans)") ? "灵动岛" : "Dynamic Island")
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
        reveal(app.buttons["island.record"], app: app)
    }
    @MainActor func testLaunchNavigationAndRotation() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout: 10))
        attach("Portrait launch")
        openLab(app)
        XCTAssertTrue(app.navigationBars["Dynamic Island"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.navigationBars["Dynamic Island"].waitForExistence(timeout: 5))
        attach("Landscape lab")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.navigationBars["Dynamic Island"].waitForExistence(timeout: 5))
        attach("Portrait lab after rotation")
    }
    @MainActor func testObservationPersistsAcrossRelaunchWithoutBeingSystemProof() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout: 10))
        openLab(app)
        let record = app.buttons["island.record"]
        reveal(record, app: app); record.tap()
        XCTAssertTrue(app.buttons["island.observation.save"].waitForExistence(timeout: 5))
        let notes = app.textViews["island.observation.notes"]
        reveal(notes, app: app); notes.tap(); notes.typeText("UI observation; simulator only.")
        app.buttons["island.observation.save"].tap()
        XCTAssertTrue(app.navigationBars["Dynamic Island"].waitForExistence(timeout: 5))
        attach("Recorded simulator observation")
        app.terminate(); app.launch()
        if !app.buttons["island.record"].waitForExistence(timeout: 5) { openLab(app) }
        let entry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "island.observation.entry.")).firstMatch
        reveal(entry, app: app)
        XCTAssertTrue(entry.label.contains("Simulator observation"))
        entry.tap()
        let savedNotes = app.staticTexts["UI observation; simulator only."]
        reveal(savedNotes, app: app)
        XCTAssertTrue(savedNotes.exists)
    }
    @MainActor func testChineseAccessibilityTextKeepsNavigationReachable() {
        let app = makeApp(chineseAccessibility: true); app.launch()
        XCTAssertTrue(app.navigationBars["Elyra"].waitForExistence(timeout: 10))
        reveal(app.staticTexts["工作区已就绪"], app: app)
        attach("Chinese accessibility launch")
        openLab(app)
        let record = app.buttons["island.record"]
        reveal(record, app: app)
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(record.frame.minX, window.minX - 1)
        XCTAssertLessThanOrEqual(record.frame.maxX, window.maxX + 1)
        attach("Chinese accessibility lab")
    }
    @MainActor private func selectArea(_ app: XCUIApplication, identifier: String, title: String) {
        let sidebarButton = app.buttons["area." + identifier]
        let tab = app.tabBars.buttons[title]
        if sidebarButton.exists && sidebarButton.isHittable { sidebarButton.tap() }
        else if tab.exists { tab.tap() }
        else if app.buttons[title].firstMatch.exists && app.buttons[title].firstMatch.isHittable {
            // iPadOS can expose compact-mode top tabs as ordinary buttons.
            app.buttons[title].firstMatch.tap()
        }
        else {
            // Label identifiers also reach their decorative image. The selectable
            // sidebar cell is the user control; the image itself is not hittable.
            let row = app.cells.containing(.any, identifier: "area." + identifier).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            XCTAssertTrue(row.isHittable)
            row.tap()
        }
    }
    @MainActor func testLanguageSwitchUpdatesCustomLabelsAndPersists() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout: 10))
        selectArea(app, identifier: "settings", title: "Settings")
        let language = app.descendants(matching: .any)["settings.language"].firstMatch
        reveal(language, app: app); language.tap()
        app.buttons["language.zh-Hans"].tap()
        XCTAssertTrue(app.navigationBars["语言"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["language.system"].label.contains("跟随系统"))
        attach("Chinese language selection")
        app.terminate(); app.launch()
        if !app.navigationBars["语言"].waitForExistence(timeout: 5) {
            selectArea(app, identifier: "settings", title: "设置")
            let link = app.descendants(matching: .any)["settings.language"].firstMatch
            reveal(link, app: app); link.tap()
        }
        XCTAssertTrue(app.navigationBars["语言"].waitForExistence(timeout: 5))
        app.buttons["language.en"].tap()
        XCTAssertTrue(app.navigationBars["Language"].waitForExistence(timeout: 5))
        app.buttons["language.system"].tap()
        XCTAssertTrue(app.navigationBars["Language"].waitForExistence(timeout: 5))
        app.buttons["language.zh-Hans"].tap()
        app.navigationBars["语言"].buttons.firstMatch.tap()
        selectArea(app, identifier: "home", title: "首页")
        XCTAssertTrue(app.staticTexts["工作区已就绪"].waitForExistence(timeout: 5))
        openLab(app, expectedTitle: "灵动岛")
        XCTAssertTrue(app.navigationBars["灵动岛"].waitForExistence(timeout: 5))
        attach("Chinese Dynamic Island appearance")
    }
    @MainActor func testAboutProfilesAndHomeActions() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Quick access"].exists)
        XCTAssertFalse(app.buttons["home.island"].exists)
        let respring = app.buttons["home.respring"]
        reveal(respring, app: app); XCTAssertFalse(respring.isEnabled)
        attach("Home device actions")
        selectArea(app, identifier: "system", title: "System")
        attach("System overview")
        app.buttons["system.device"].tap()
        let connect = app.buttons["device.connect"]
        XCTAssertTrue(connect.waitForExistence(timeout: 5))
        XCTAssertFalse(connect.isEnabled)
        XCTAssertTrue(app.staticTexts["Device system access is unavailable in the Simulator."].exists)
        attach("Simulator device connection")
        app.navigationBars["Device configuration"].buttons.firstMatch.tap()
        selectArea(app, identifier: "settings", title: "Settings")
        app.buttons["About Elyra"].tap()
        XCTAssertTrue(app.navigationBars["About Elyra"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["about.profiles"].exists)
        for id in ["github", "douyin", "xiaohongshu"] {
            let card = app.buttons["profile." + id]
            reveal(card, app: app)
            XCTAssertTrue(card.isHittable)
        }
        attach("About account cards")
    }
    @MainActor func testSystemFeatureRoundTripKeepsTileNavigationAndVisibleModify() {
        let app = makeApp(); app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout: 10))
        selectArea(app, identifier: "system", title: "System")
        for category in ["display", "device", "ipad", "intelligence", "advanced"] {
            let tile = app.buttons["system.category." + category].firstMatch
            reveal(tile, app: app); tile.tap()
            XCTAssertTrue(app.scrollViews["system.category.page"].waitForExistence(timeout: 5))
            let feature = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "system.feature.")).firstMatch
            reveal(feature, app: app); feature.tap()
            let modify = app.buttons["feature.modify"]
            reveal(modify, app: app)
            XCTAssertFalse(modify.isEnabled, "Simulator must not apply a device preset")
            XCTAssertFalse(app.staticTexts["Dependencies & risk"].exists)
            app.navigationBars.matching(NSPredicate(format: "identifier != %@", "Elyra")).firstMatch.buttons.firstMatch.tap()
            XCTAssertTrue(app.scrollViews["system.category.page"].waitForExistence(timeout: 5))
            app.navigationBars.matching(NSPredicate(format: "identifier != %@", "Elyra")).firstMatch.buttons.firstMatch.tap()
            XCTAssertTrue(app.scrollViews["system.dashboard"].waitForExistence(timeout: 5))
        }
        attach("System tiles after feature round trips")
    }
    @MainActor func testConfigurationPlanSavesAndPersistsWithoutSystemWrite() {
        let app=makeApp();app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout:10))
        selectArea(app,identifier:"system",title:"System")
        let plans=app.buttons["system.plans"];reveal(plans,app:app);plans.tap()
        app.buttons["plans.new"].tap()
        let name=app.textFields["plan.name"];XCTAssertTrue(name.waitForExistence(timeout:5));name.tap();name.typeText("Display plan")
        let feature=app.switches["plan.feature.dynamicIsland"];reveal(feature,app:app)
        feature.coordinate(withNormalizedOffset: CGVector(dx:0.9,dy:0.5)).tap()
        XCTAssertEqual(feature.value as? String, "1")
        app.buttons["plan.save"].tap()
        XCTAssertTrue(app.staticTexts["Display plan"].waitForExistence(timeout:10))
        XCTAssertFalse(app.buttons["Modify"].firstMatch.isEnabled)
        attach("Saved configuration plan")
        app.terminate();app.launch()
        if !app.staticTexts["Display plan"].waitForExistence(timeout:5) {
            selectArea(app,identifier:"system",title:"System")
            let plans=app.buttons["system.plans"];reveal(plans,app:app);plans.tap()
        }
        XCTAssertTrue(app.staticTexts["Display plan"].waitForExistence(timeout:10))
    }
    @MainActor func testWindowDisplayMeasurementControls() {
        let app=makeApp();app.launch()
        XCTAssertTrue(app.staticTexts["Workspace ready"].waitForExistence(timeout:10))
        selectArea(app,identifier:"tools",title:"Tools")
        let link=app.buttons["tools.display"];reveal(link,app:app);link.tap()
        XCTAssertTrue(app.navigationBars["Window & display"].waitForExistence(timeout:5))
        let measurement=app.buttons["display.measure"];reveal(measurement,app:app);measurement.tap()
        XCTAssertTrue(measurement.label.contains("Stop measurement"));measurement.tap()
        XCTAssertTrue(measurement.label.contains("Start measurement"))
        attach("Window and display diagnostics")
    }
    @MainActor private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
