# Test report

**Elyra 0.3.0, build 18** passed all three jobs in [run 43617128024](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024). Qualified source: `b0f2232d3ff989cfae673dce94241dc4eebd563e`, tag `v0.3.0-dev`. Later documentation-only commits do not change this IPA's code identity.

| Check | Result |
| --- | --- |
| Linux core | 76 passed, Swift 6.0.3 |
| macOS core | 76 passed, Apple Swift 6.2.4 |
| Python IPA negative tests | 8 passed |
| Localization | 523 matching English/Simplified Chinese keys, zero missing fixed translations |
| Project, resources and workflows | Reproducible generation and static checks passed |
| Xcode analysis / Release archive | Passed, Xcode 26.3 (17C529), SDK 26.2 |
| iPhone UI | 5 passed, zero failures/skips; iPhone SE (3rd generation), arm64 Simulator 26.2 (23C54) |
| iPad UI | 5 passed, zero failures/skips; iPad mini (A17 Pro), arm64 Simulator 26.2 (23C54) |
| Downloaded IPA | Structure and SHA-256 independently rechecked; native access symbols and all three account image assets present |
| App identity | `org.elyra.Elyra`, arm64, minimum OS 17.0, version 0.3.0 (18) |
| Signing | Unsigned; matching App Group entitlement template supplied alongside the IPA |
| Physical installation, system writes, restoration, Respring | Not tested |

[Download unsigned IPA artifact](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024/artifacts/14122258455). Extract its wrapper ZIP, then verify `Elyra-unsigned.ipa` against `SHA256SUMS`. SHA-256: `ee171a77bc4254da198e08653a16e7ddf062a566f50560211db307c9fc291487`. The supplied `Elyra.entitlements` matches the source template; it does not grant permissions without a valid provisioning profile and signature.

The [guarded release workflow](https://github.com/XiaoRui114514/Elyra/actions/runs/43618402178) also passed and retained `v0.3.0-dev` as a draft prerelease with the same unsigned IPA, checksum, report and entitlement template.

## Coverage

Fourteen system-transaction tests use temporary files and injected access/failure modes. They exercise direct capture, exact XML/binary byte restoration, protected fields, stale sessions, external changes, canonical generation identity, corrupt backups, partial writes, failed rollback, persistent recovery journals, replaced inodes, cross-installation rejection and concurrent windows. These tests validate the transaction policy, not the operating system's native access mechanism.

Other core tests cover typed plist editing, local document/asset integrity, drafts, text versions, bounded ZIP/tendies checks, Dynamic Island field preservation and observations, device-build parsing and language resolution.

The five UI scenarios cover navigation/rotation, maximum Chinese accessibility text, observation persistence, immediate language changes/relaunch persistence, and the Home/System/About flow. They verify Respring and connection controls are disabled in the simulator and all three account cards are directly reachable in About. Tests do not open external account URLs, invoke native access or execute Respring. UI screenshots use the Debug host's project build number; the Release archive uses build 18.

A regression in the earlier candidate's test locator treated compact iPad top tabs as sidebar cells. The locator now recognizes their native button representation and still requires visible, hittable navigation. The final run passed both simulator suites.

## Evidence and limits

[Run/artifact manifest](audit/ci-0.3.json), [IPA report](audit/ci-0.3-ipa-report.json), [toolchain excerpts](audit/ci-0.3-toolchain.txt), [macOS core log](audit/swift-test-macos-0.3.log), [Linux core log](audit/swift-test-linux-0.3.log), [iPhone summary](audit/ci-0.3-iphone-ui-summary.json), [iPad summary](audit/ci-0.3-ipad-ui-summary.json), [original screenshots](screenshots/README.md). Complete logs and xcresult bundles remain in the run artifacts.

Screenshot review confirmed the direct account rows, official publisher icons, restrained brand backgrounds, compact/side-by-side System categories and wrapping accessibility text. Window-policy tests sweep 320–1600 points; rotation and policy tests do not replace continuous Stage Manager resize, external-display, VoiceOver or multiwindow acceptance. No iOS/iPadOS 27 runtime/physical qualification or system Dynamic Island geometry repair is established. Native temporary-cache cleanup during abrupt process death remains a separate unverified risk documented in KNOWN_ISSUES.

[0.2 historical qualification](TEST_REPORT_0.2.md) applies only to its recorded source and build 10.
