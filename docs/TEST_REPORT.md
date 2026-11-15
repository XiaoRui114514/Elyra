# Test report

**Elyra 0.4.1, build 28** passed the required jobs in [run 43680976089](https://github.com/XiaoRui114514/Elyra/actions/runs/43680976089). Qualified app/build source: `94942ddebc8ae60474be8bb10620e8f503420ebb`; tag `v0.4.1-dev`. Later documentation changes do not change the app code.

| Check | Result |
| --- | --- |
| Swift core | 102 passed on Linux and macOS |
| Python IPA checks | 14 passed |
| Localization | 625 matching English/Simplified Chinese keys, no missing fixed translations |
| Project/static checks | Reproducible generation, syntax, workflow and repository checks passed |
| Xcode analysis / Release archive | Passed; Xcode 26.3 (17C529), SDK 26.2 |
| iPhone UI | 9 passed; no failures/skips; iPhone SE (3rd generation), arm64 Simulator 26.2 (23C54) |
| iPad UI | 9 passed; no failures/skips; iPad mini (A17 Pro), arm64 Simulator 26.2 (23C54) |
| Downloaded IPAs | Both independently checked for structure, signature mode, embedded groups and SHA-256 |
| Re-signable IPA | Ad-hoc App Group template, no developer team/profile; legitimate re-signing required |
| Unsigned IPA | No embedded signature; legitimate signing required |
| Physical installation / system effects | Not tested |

[Download re-signable IPA](https://github.com/XiaoRui114514/Elyra/releases/download/v0.4.1-dev/Elyra-resignable.ipa) · [Release page](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.4.1-dev)

- Re-signable SHA-256: `52fa3a0937ead308edd2d89cd62d07ea24d8383cb747281769486940c7b96fba`
- Unsigned SHA-256: `361ff9926d145aa387995d3d2ae264449afe846b6e204d371f55d0dc037424ce`

## Coverage

The core suite adds seven-field intelligence/region merging, sales-region/identity/Siri-type preservation, synchronized display-name fields, absent/malformed artwork, invalid names, actual on/off/partial/unknown state mapping, explicit disable behavior, legacy backup-policy compatibility, one-transaction preference writes, rollback, stale proposals and captured tablet-subtype restoration. Existing plist, file, archive, backup and concurrency coverage remains enabled.

The ninth UI scenario enters the model-name editor, edits a synthetic name and confirms device writes stay disabled in Simulator, then enters the mainland intelligence recipe and checks its guarded apply control. Existing Home/About, language/relaunch, maximum Chinese accessibility text, rotation, observation persistence, all five System category round trips and window/display tests remain enabled. CI preboots the selected simulator before invoking XCTest. No native system access or Respring is run in Simulator tests.

[Run/artifact manifest](audit/ci-0.4.1.json), [re-signable report](audit/ci-0.4.1-resignable-ipa-report.json), [unsigned report](audit/ci-0.4.1-ipa-report.json), [macOS core log](audit/swift-test-macos-0.4.1.log), [Linux core log](audit/swift-test-linux-0.4.1.log), [iPhone summary](audit/ci-0.4.1-iphone-ui-summary.json), [iPad summary](audit/ci-0.4.1-ipad-ui-summary.json), [simulator screenshots](screenshots/README.md).

## Limits

A capability flag's on/off label refers to the captured cache value, not independent verification of hardware or Apple-service activation. The combined intelligence recipe preserves device-specific Siri; it does not promise service availability. Model-name writes target three display fields; actual Settings rendering and restoration remain unverified on physical devices. Model Number, Serial Number, OS Version and Capacity research is documented separately in [RESEARCH_0.4.1](RESEARCH_0.4.1.md); no unverified About override is presented as completed.

Signing/installation, per-build native effects, iOS/iPadOS 27 runtime, continuous Stage Manager resize, external displays, VoiceOver and simultaneous multiwindow UI acceptance remain pending. System Dynamic Island geometry has no verified repair. Native cache-link cleanup under abrupt termination remains separate from the system-write journal.

Historical reports: [0.4](TEST_REPORT_0.4.md), [0.3](TEST_REPORT_0.3.md), [0.2](TEST_REPORT_0.2.md).

The [guarded release workflow](https://github.com/XiaoRui114514/Elyra/actions/runs/43682485307) passed. Both public IPA downloads returned HTTP 200 without authorization/cookies and matched the qualified hashes; [download evidence](audit/public-download-0.4.1.json).
