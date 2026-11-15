# Responsive interface

WindowLayout uses the current scene window’s safe-area-adjusted bounds together with Dynamic Type. A shared UIKit observer updates on window/safe-area layout changes; it does not use main-screen bounds. SwiftUI still applies normal keyboard avoidance inside pages. Keyboard-reduced content height no longer changes the root navigation branch. Compact navigation applies below 720 points, below 360 points in height or at accessibility text sizes. Medium windows use a sidebar; widths at least 1100 points enable parallel document/difference content. The same routes and feature catalog serve every window.

Navigation uses NavigationStack and NavigationSplitView. SceneStorage retains selected area, independent paths for each area, search and draft identifiers. Shared Workspace and SystemConfigurationStore actors protect local and device writes. System overview and category pages share adaptive tiles without disclosure chevrons, and use one column at accessibility text sizes. Feature detail shares the same panels and places Modify near the current-state controls. About shows its three account rows directly, without an intermediate sheet. Language changes update locale and bundled text lookups without resetting the root view or drafts.

| Scenario | Coverage |
| --- | --- |
| Compact iPhone | Simulator navigation and portrait/landscape checks in CI |
| iPad portrait/landscape | Sidebar/detail and rotation checks in CI |
| Large Dynamic Type | Chinese maximum-accessibility-size reachability checks in CI |
| Width policy | Core sweep from 320 to 1600 points |
| Stage Manager continuous resize | Implementation present; runtime acceptance pending |
| Narrow Split View / arbitrary windows | Geometry policy present; continuous drag test pending |
| Parallel document/difference editor | Implemented; dedicated UI workflow pending |
| External display / multiple windows | WindowGroup and shared state present; hardware/UI acceptance pending |
| VoiceOver | Native labels and controls present; listening review pending |

Actual run identities, simulator models and screenshots belong in TEST_REPORT. Policy sweeps and rotation do not constitute continuous-window-resize testing. Scroll/disclosure persistence and search-focus behavior across all transitions remain open work.

Build 18 passed five UI scenarios per simulator in [run 43617128024](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024). Original screenshots were reviewed for direct About account cards, adaptive System categories, Chinese accessibility text and iPad sidebar/detail. Source identities and hashes are preserved in [screenshots](screenshots/README.md). Continuous Stage Manager drag-resize and physical display/window acceptance remain pending.

The 0.4 regression suite adds repeated enter/back navigation through all five System categories, visible Modify checks, configuration-plan save/relaunch and window/display controls. Final candidate results belong in TEST_REPORT; test helpers scroll both directions to respect retained offsets and confirm that controls are actually reachable.

0.4.0 (26) passed eight UI scenarios per simulator in [run 43676397713](https://github.com/XiaoRui114514/Elyra/actions/runs/43676397713), including all five System category round trips, plan persistence and display controls. [Original 0.4 screenshots](screenshots/README.md) retain source identities and hashes. This does not extend coverage to continuous Stage Manager resize.

0.4.1 source `94942ddebc8ae60474be8bb10620e8f503420ebb` passes nine scenarios per simulator, adding model-name editing and the guarded mainland intelligence entry. Selected-row backgrounds retain rounded corners. This does not qualify continuous hardware window resizing or private SpringBoard appearance.

0.4.2 adds explicit model-name focus and keyboard Done, per-scene input drafts, and one sorted grid for capabilities and display preferences. A dedicated regression opens the software keyboard in portrait and landscape, types real text, dismisses/reopens it and checks the draft after returning through the category. Qualification results are recorded in TEST_REPORT.

0.4.2 source `8bcdb02cc1b5b4f56969e354405ac9a471aa6866` passes all 11 UI scenarios on each simulator in [run 43707797116](https://github.com/XiaoRui114514/Elyra/actions/runs/43707797116), first attempt. Portrait/landscape model-name software-keyboard typing, Done/reopen and category-return draft retention are verified at app level. These checks do not establish continuous Stage Manager drag-resize or physical-device behavior.
