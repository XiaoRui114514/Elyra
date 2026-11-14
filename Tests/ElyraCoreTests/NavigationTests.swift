// SPDX-License-Identifier: GPL-3.0-only
import XCTest
@testable import ElyraCore
final class NavigationTests: XCTestCase {
    func testReturningFromFeaturePreservesCategoryAndOtherAreas() throws {
        var state = SceneNavigation()
        state.setPath([.category("display"), .capability("dynamicIsland")], for: .system)
        state.setPath([.language], for: .settings)
        var system = state.path(for: .system); system.removeLast(); state.setPath(system, for: .system)
        XCTAssertEqual(state.path(for: .system), [.category("display")])
        XCTAssertEqual(state.path(for: .settings), [.language])
        XCTAssertEqual(state.path(for: .home), [])
        system.removeLast(); state.setPath(system, for: .system)
        XCTAssertTrue(state.path(for: .system).isEmpty)
        let restored = SceneNavigation.restored(try JSONEncoder().encode(state), legacy: nil, area: .home)
        XCTAssertEqual(restored, state)
    }
    func testLegacyPathMigratesIntoOnlyItsOwnArea() throws {
        let legacy = try JSONEncoder().encode([Screen.category("advanced"), .capability("internal")])
        let state = SceneNavigation.restored(nil, legacy: legacy, area: .system)
        XCTAssertEqual(state.path(for: .system), [.category("advanced"), .capability("internal")])
        XCTAssertTrue(state.path(for: .settings).isEmpty)
        XCTAssertEqual(SceneNavigation.restored(Data("broken".utf8), legacy: nil, area: .home), SceneNavigation())
    }
    func testAccessStatesDoNotEquateUncheckedAndDenied() {
        func state(read: Bool = false, write: Bool = false, checking: Bool = false, failed: Bool = false, recovery: Bool = false) -> DeviceAccessState {
            .resolve(simulator: false, checking: checking, readable: read, writable: write, failed: failed, recovery: recovery)
        }
        XCTAssertEqual(state(), .unchecked)
        XCTAssertEqual(state(checking: true), .checking)
        XCTAssertEqual(state(read: true), .readOnly)
        XCTAssertEqual(state(read: true, write: true), .readWrite)
        XCTAssertEqual(state(failed: true), .failed)
        XCTAssertEqual(state(read: true, write: true, recovery: true), .recovery)
    }
}
