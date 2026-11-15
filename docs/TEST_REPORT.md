# Test report

**Elyra 0.4.0, build 26** passed all required jobs in [run 43676397713](https://github.com/XiaoRui114514/Elyra/actions/runs/43676397713). Qualified code source: `b1e85e16a8c3195919fc4bc0ec5d33d4689a21f7`, tag `v0.4.0-dev`. Later documentation-only commits do not change the app code.

| Check | Result |
| --- | --- |
| Swift core | 93 passed on macOS; Linux core checks also passed |
| Python IPA tests | 14 passed |
| Localization | 607 matching English/Simplified Chinese keys |
| Project/resources/static checks | Passed |
| Xcode analysis and Release archive | Passed; Xcode 26.3 (17C529), SDK 26.2 |
| iPhone UI | 8 passed; zero failures/skips; iPhone SE (3rd generation), arm64 Simulator 26.2 (23C54) |
| iPad UI | 8 passed; zero failures/skips; iPad mini (A17 Pro), arm64 Simulator 26.2 (23C54) |
| Downloaded packages | Both arm64 IPAs independently verified; exact checksums and reports retained |
| Re-signable signature | Ad-hoc; App Group template embedded; no developer team/profile |
| Fully unsigned package | No signature directory or embedded group entitlement |
| Installation and system effects | Not physically tested |

[Download re-signable IPA](https://github.com/XiaoRui114514/Elyra/releases/download/v0.4.0-dev/Elyra-resignable.ipa) · [Development release](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.4.0-dev). Both packages require legitimate signing/provisioning. Ad-hoc packaging supplies a discoverable entitlement template; actual system access still requires a usable final signature/container and permission probe.

- Re-signable SHA-256: `c17151636c33c1fe931c319ec39440236067555deaa303cf36da6af5a57a2234`
- Unsigned SHA-256: `cd9aa85f2776f636cb01fd25a20c469d676ec159f9344d15ca863f6b72f086f4`

## Coverage

Core tests exercise typed plist editing, conflict detection, verified backups/restoration, transaction failures/recovery, data-only configuration-plan import/export, optimistic plan saves, combined plan transactions, recorded Dynamic Island subtype restoration, Boolean preservation, offline backup verification and three-way draft rebasing. Navigation tests preserve independent paths per area and cover layout policy widths from 320 to 1600 points.

Eight UI scenarios per simulator cover Home/About/connection controls; maximum Chinese accessibility text; saved configuration plans across relaunch; immediate language changes and persistence; portrait/landscape navigation; observation notes across relaunch; repeated entry/back through all five System categories with visible Modify; and window/display measurement controls. Controls must remain reachable by scrolling. Native device access and Respring remain disabled in the simulator.

Candidate failures were inspected using full logs, UI hierarchies and recordings. Fixes include Apple CGFloat formatting, visible plan validation, accurate switch activation, explicit sidebar actions after relaunch and scroll-aware reachability. No feature or failing scenario was removed. The iPad first attempt had a Simulator launch-progress timeout before the first app flow; its other seven scenarios passed. The failed iPad task was rerun on the same commit, with all eight scenarios required. Package/core and iPhone results remain from the first attempt. This final set of required checks qualifies the code above. See the retained [first-attempt timeout summary](audit/ci-0.4-ipad-attempt1-launch-timeout.json).

## Evidence and limits

[Run/artifact manifest](audit/ci-0.4.json), [re-signable report](audit/ci-0.4-resignable-ipa-report.json), [unsigned report](audit/ci-0.4-ipa-report.json), [toolchain](audit/ci-0.4-toolchain.txt), [macOS core log](audit/swift-test-macos-0.4.log), [iPhone summary](audit/ci-0.4-iphone-ui-summary.json), [iPad summary](audit/ci-0.4-ipad-ui-summary.json), [original simulator screenshots](screenshots/README.md). Full logs and xcresult bundles remain in the run artifacts. Screenshots use the Debug host's build number; the Release package build is recorded above.

Physical installation, per-build native read/write/restore, Respring, iOS/iPadOS 27 runtime, continuous Stage Manager resize, external displays, VoiceOver and simultaneous multiple-window acceptance remain unverified. App callback measurements do not measure panel scan rate/PWM. No system Dynamic Island radius/layout repair is established. Native temporary-cache cleanup during abrupt termination remains outside the system-write journal.

Historical qualification: [0.3](TEST_REPORT_0.3.md), [0.2](TEST_REPORT_0.2.md).

The [guarded release workflow](https://github.com/XiaoRui114514/Elyra/actions/runs/43678344548) passed and `v0.4.0-dev` is published as a development prerelease. Both direct IPA downloads returned HTTP 200 without authorization or cookies and matched the qualified hashes; [public download evidence](audit/public-download-0.4.json).
