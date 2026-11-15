# Responsive interface

WindowLayout uses actual window width and height together with Dynamic Type. Compact navigation applies below 720 points, below 360 points in height or at accessibility text sizes. Medium windows use a sidebar; widths at least 1100 points enable parallel document/difference content. The same routes and feature catalog serve every window.

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
