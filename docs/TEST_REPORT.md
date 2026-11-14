# 0.3 candidate

Native MobileGestalt access, restricted device writes, verified device backups/recovery, updated Home/System/About and five simulator UI scenarios are under Apple CI validation. Local Swift suite: 76 passed. No physical system write or Respring result is claimed. The 0.2 results below apply only to their recorded source.

# Test report

**Elyra 0.2.0, build 10** passed all three jobs in [run 43593518290](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290). Tested source: `38a362f817be8b13a4c96d7d9380f9320c428c7d`, tag `v0.2.0-dev`. Later documentation-only commits do not change this artifact's code identity.

| Check | Current result |
| --- | --- |
| Linux core | 63 passed, Swift 6.0.3 |
| Python IPA negative tests | 8 passed |
| Localization resources | 430 matching English/Simplified Chinese keys, no unclassified fallback |
| Project/resources/workflow checks | Passed locally |
| macOS core | 63 passed, Apple Swift 6.2.4 |
| Xcode analysis / device archive | Passed; Xcode 26.3 (17C529), SDK 26.2 |
| iPhone UI | 4 passed, zero failures/skips; iPhone SE (3rd generation), arm64 Simulator 26.2 (23C54) |
| iPad UI | 4 passed, zero failures/skips; iPad mini (A17 Pro), arm64 Simulator 26.2 (23C54) |
| IPA structure/readback | Passed on CI and independently after download; `org.elyra.Elyra`, arm64, minimum OS 17.0 |
| Signing | Unsigned build pipeline; no certificates supplied |
| Physical installation/system effects | Not tested |

The core suite covers typed plist values, baseline integrity, transaction conflicts/recovery, Dynamic Island field preservation, observation/schema migration, text-file versions, bounded ZIP validation, device-build parsing and language resolution. Four UI scenarios per simulator cover navigation/rotation, Chinese accessibility text, observation persistence and actual language switching/persistence.

Download [the unsigned IPA artifact](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290/artifacts/14112913746) and extract its wrapper ZIP. IPA SHA-256: `a47c784cbcc27b6c64a40835586a9e6d38000d2c0ed99fca6be25e846874df55`.

Evidence: [run/artifact manifest](audit/ci-final.json), [IPA report](audit/ci-final-ipa-report.json), [toolchain excerpts](audit/ci-final-toolchain.txt), [macOS core log](audit/swift-test-macos.log), [iPhone summary](audit/ci-final-iphone-ui-summary.json), [iPad summary](audit/ci-final-ipad-ui-summary.json), [original simulator screenshots](screenshots/README.md). Full logs and xcresult bundles are retained in the run artifacts.

Screenshot review confirmed translated titles/sidebar/labels after an in-app language change and reachable wrapping at maximum accessibility text size. The navigation-title refresh regression was corrected through explicit localized title values; tests continued to assert actual displayed text. See [regression evidence](audit/localization-title-regression.txt). Dedicated file-picker/editor/restore/archive UI workflows remain outside this four-scenario suite.

Window-policy tests sweep widths 320–1600. They do not replace continuous Stage Manager resize, external-display or physical-device testing. Simulator rendering does not establish system Dynamic Island modification.
