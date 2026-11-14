# Elyra

A SwiftUI configuration and file toolkit for iPhone and iPad. Navigation adapts to the current window size, including compact windows and larger sidebar layouts.

[简体中文](README_ZH-CN.md) · [Features](docs/FEATURE_MATRIX.md) · [Build and tests](docs/TEST_REPORT.md) · [Building](docs/BUILDING.md) · [Known issues](docs/KNOWN_ISSUES.md)

Elyra 0.3 adds a native MobileGestalt connection and capability writer using the pinned upstream access modules. A usable signed App Group is required when direct access is unavailable. Exact build permissions are probed on the device; iOS/iPadOS 26 and 27 are not blanket guarantees. Imported files remain separate local documents. New Apple CI qualification is pending; the linked build 10 below is the earlier 0.2 local-tool release.

[Download unsigned build 10](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290/artifacts/14112913746) · [Passed CI](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290). Legitimate signing is required; physical installation is untested.

- Browse and edit eight plist types, search nested fields, stage changes and review differences before saving.
- Create verified backups, restore original bytes and detect stale edits across windows.
- Read the live device cache, stage supported capability/artwork changes, confirm writes, verify readback and restore device-bound backups. Protected identity and binary fields are excluded.
- Inspect Dynamic Island configuration without claiming control over system capsule radius.
- Record appearance across idle, recording, timer, call, media and multiple-activity states.
- Preview and export files; edit UTF-8 text with version backups and recovery.
- Inspect ZIP and `.tendies` archives with bounded expansion, path and CRC checks.
- Choose English, Simplified Chinese or Follow System in Settings → Language.
- Redesigned System overview, manual experimental Respring and creator-profile cards in About.

Feature names follow Apple terminology and the upstream implementations. See [terminology and localization](docs/NAMING_AND_LOCALIZATION.md) and [Dynamic Island research](docs/DYNAMIC_ISLAND_RESEARCH.md).

[GitHub Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml) runs core tests, Xcode analysis and iPhone/iPad UI tests, then archives an arm64 device app and validates the IPA. Artifacts are unsigned and require legitimate signing/provisioning. Installation status and exact qualified source are listed in [the test report](docs/TEST_REPORT.md).

Open `Elyra.xcodeproj` for app development; run `swift test` for the portable core. GPL-3.0-only. Copyright and dependency notices are retained in [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
