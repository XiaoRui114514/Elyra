# 0.4.2 qualification

Qualified app source: `8bcdb02cc1b5b4f56969e354405ac9a471aa6866`.
[Build run 43707797116](https://github.com/XiaoRui114514/Elyra/actions/runs/43707797116) passed all three jobs on the first attempt. The app is 0.4.2 (29), universal arm64, deployment target iOS 17. Xcode 26.3 (17C529), Swift 6.2.4, SDK/runtime 26.2 were used. Documentation-only updates after qualification do not qualify changes to app code.

| Check | Result |
| --- | --- |
| Portable core, Linux | 105 tests, no failures |
| Portable core, macOS | 105 tests, no failures |
| Python negative/packaging checks | 14 tests passed |
| Repository, localization, reproducible project and workflow checks | Passed; 626 matching language keys, 105 feature-matrix rows |
| Xcode static analysis | Passed; existing CADisplayLink deinitializer concurrency warning remains for Swift 6 migration |
| iPhone SE 3 Simulator, 26.2 (23C54) | 11 tests passed, zero skipped/failed |
| iPad mini A17 Pro Simulator, 26.2 (23C54) | 11 tests passed, zero skipped/failed |
| Release archive and IPA structure | Both arm64 packages passed CI and independent downloaded-package verification |

## Regression evidence

The new model-name scenario checks the entry shares its peer tile width, opens the software keyboard in portrait, types real text, dismisses with Done, rotates to landscape, reopens and types again, then returns through the category and verifies the draft. Native window bounds now determine navigation breakpoints while SwiftUI continues normal keyboard avoidance. The independent RegionCode scenario selects a real menu value and confirms Simulator cannot apply system writes.

Existing navigation/rotation, all-five-category round trips, language/relaunch, maximum Chinese accessibility text, observations, saved configuration plans and display diagnostics remain enabled. Original screenshots were inspected for the keyboard/Done control, retained editor content, normal grid placement, region selection and shortened intelligence title. These are simulator app-interface observations, not physical system-effect evidence.

Core additions exercise all seven bounded region codes, rejection of malformed/unsupported values, exact restoration of absent or uncatalogued captured originals, preservation of unrelated model/intelligence edits and rejection of stale transactions. Existing backup-policy compatibility, rollback, plist/file/archive and concurrency tests remain enabled.

## Packages and evidence

- Re-signable SHA-256: `0172da1c4691db711a98e08ecad844d11fc0e92e583594ae4ecd8013b8c70a19`
- Unsigned SHA-256: `ac6308f81a51d198830ee066ee79f120ce5a54a7736fc43b4f2e43126e8e1ce4`

[Run/artifact manifest](audit/ci-0.4.2.json), [re-signable report](audit/ci-0.4.2-resignable-ipa-report.json), [unsigned report](audit/ci-0.4.2-ipa-report.json), [macOS core log](audit/swift-test-macos-0.4.2.log), [Linux core log](audit/swift-test-linux-0.4.2.log), [iPhone summary](audit/ci-0.4.2-iphone-ui-summary.json), [iPad summary](audit/ci-0.4.2-ipad-ui-summary.json), [original screenshots](screenshots/README.md).

The [guarded release workflow](https://github.com/XiaoRui114514/Elyra/actions/runs/43709385665) passed. The [public development release](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.4.2-dev) supplies [Elyra-resignable.ipa](https://github.com/XiaoRui114514/Elyra/releases/download/v0.4.2-dev/Elyra-resignable.ipa). Both IPA assets were actually downloaded without authorization headers or cookies: HTTP 200, qualified SHA-256 and exact byte counts matched. [Anonymous download evidence](audit/public-download-0.4.2.json).

## Limits

The re-signable package has an ad-hoc App Group template and requires legitimate signing/provisioning; the unsigned package requires signing too. Physical installation, keyboard/input acceptance, Settings display-name rendering/restoration, per-build system writes, service activation and iOS/iPadOS 27 runtime remain unverified. Continuous Stage Manager resize, external displays, VoiceOver and simultaneous multiwindow UI acceptance remain pending. No system Dynamic Island geometry repair is claimed.

Region codes are raw upstream values; no unverified territory mapping is added. Model naming changes three display fields, not hardware identifiers. Other General → About items remain research. Native cache-link cleanup under abrupt termination remains separate from the system-write journal.

Historical reports: [0.4.1](TEST_REPORT_0.4.1.md), [0.4](TEST_REPORT_0.4.md), [0.3](TEST_REPORT_0.3.md), [0.2](TEST_REPORT_0.2.md).
