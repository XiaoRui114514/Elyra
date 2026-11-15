# Elyra

A SwiftUI configuration and file toolkit for iPhone and iPad. Navigation and content adapt to the current window size.

[简体中文](README_ZH-CN.md) · [Features](docs/FEATURE_MATRIX.md) · [Tests](docs/TEST_REPORT.md) · [Building](docs/BUILDING.md) · [Known issues](docs/KNOWN_ISSUES.md)

[Download 0.4.2 re-signable IPA](https://github.com/XiaoRui114514/Elyra/releases/download/v0.4.2-dev/Elyra-resignable.ipa) · [Development release](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.4.2-dev)

Both re-signable and unsigned IPAs require legitimate signing/provisioning. The re-signable package embeds an ad-hoc App Group template for signing-tool discovery. Installation and physical system effects have not been tested; exact source, checksums and simulator results are in [the test report](docs/TEST_REPORT.md).

- **Intelligence:** one reviewed mainland configuration combines seven supported capability presets and RegionCode, preserving sales-region suffixes and device-specific Siri. An independent RegionCode selector is also available.
- **Model name:** native keyboard focus and Edit/Done controls, retained scene drafts, a shared adaptive device tile, three synchronized display fields and targeted restoration. Feature cards display actual on/off states and enabled checkmarks.
- **System:** automatic live MobileGestalt access checks, adaptive feature tiles, direct Modify actions, reviewed differences, verified device backups/readback and recorded-value restoration. Actual access depends on the final signature/container and file permission probe; no blanket OS-version guarantee.
- **Configuration plans:** save, import and export feature selections, resolve conflicts and review one combined device transaction.
- **Documents and files:** edit eight plist types, search nested fields, retain drafts, preview/export assets, edit UTF-8 text with version backups and inspect ZIP/`.tendies` archives with bounded path/CRC validation.
- **Backups:** inspect and export verified device backups offline; compare a backup with the current capture before a separately confirmed restoration. Imported files never establish device trust.
- **Diagnostics:** current-window dimensions, safe areas, display scale, pixel bounds, refresh capability and EDR headroom; optional application callback sampling.
- **Dynamic Island:** configuration inspection and recorded-field restoration under Display, plus appearance observations and a clearly labeled app preview. No verified system corner-radius/layout repair is claimed.
- **Interface:** independent navigation per area, native controls, English/Simplified Chinese/Follow System, manual experimental Respring and direct account cards in About.

System capabilities share one engine across iPhone and iPad. Hardware and Apple-service availability are distinct from capability flags. Appearance installation, full directory browsing and pairing remain incomplete; the [feature matrix](docs/FEATURE_MATRIX.md) records migration status.

[GitHub Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml) runs core/Python checks, Xcode analysis and eleven UI scenarios on each iPhone/iPad simulator, then validates both arm64 IPA packages. Continuous Stage Manager resize, external displays, VoiceOver and iOS/iPadOS 27 runtime acceptance remain pending.

Open `Elyra.xcodeproj` for app development; run `swift test` for the portable core. GPL-3.0-only. Required copyright and dependency notices remain in [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). [Source review](docs/REVIEW_0.4.md) · [Dynamic Island research](docs/DYNAMIC_ISLAND_RESEARCH.md)
