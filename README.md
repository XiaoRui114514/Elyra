# Elyra

A SwiftUI configuration and file toolkit for iPhone and iPad. Navigation adapts to the current window size, including compact windows and larger sidebar layouts.

[简体中文](README_ZH-CN.md) · [Features](docs/FEATURE_MATRIX.md) · [Build and tests](docs/TEST_REPORT.md) · [Building](docs/BUILDING.md) · [Known issues](docs/KNOWN_ISSUES.md)

Elyra 0.2 is a development release with local plist editing, verified backups, managed files and archive inspection. On-device system configuration access is not implemented. Imported files remain in the app's workspace.

[Download unsigned build 10](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290/artifacts/14112913746) · [Passed CI](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290). Legitimate signing is required; physical installation is untested.

- Browse and edit eight plist types, search nested fields, stage changes and review differences before saving.
- Create verified backups, restore original bytes and detect stale edits across windows.
- Inspect Dynamic Island capability and artwork fields; restore recorded fields in local copies.
- Record appearance across idle, recording, timer, call, media and multiple-activity states.
- Preview and export files; edit UTF-8 text with version backups and recovery.
- Inspect ZIP and `.tendies` archives with bounded expansion, path and CRC checks.
- Choose English, Simplified Chinese or Follow System in Settings → Language.

Feature names follow Apple terminology and the upstream implementations. See [terminology and localization](docs/NAMING_AND_LOCALIZATION.md) and [Dynamic Island research](docs/DYNAMIC_ISLAND_RESEARCH.md).

[GitHub Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml) runs core tests, Xcode analysis and iPhone/iPad UI tests, then archives an arm64 device app and validates the IPA. Artifacts are unsigned and require legitimate signing/provisioning. Installation status and exact qualified source are listed in [the test report](docs/TEST_REPORT.md).

Open `Elyra.xcodeproj` for app development; run `swift test` for the portable core. GPL-3.0-only. Copyright and dependency notices are retained in [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
