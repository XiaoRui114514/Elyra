# Installation

GitHub Actions generates a genuine arm64 `Payload/Elyra.app` and packages it as an unsigned IPA. The exact qualified build, checksum and download link are recorded in TEST_REPORT.md.

Qualified build: **0.2.0 (10)**, [source tag](https://github.com/XiaoRui114514/Elyra/tree/v0.2.0-dev), [unsigned artifact](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290/artifacts/14112913746). SHA-256: `a47c784cbcc27b6c64a40835586a9e6d38000d2c0ed99fca6be25e846874df55`.

1. Choose a completely successful run in [Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml).
2. Download `Elyra-unsigned-<source SHA>` and extract the artifact wrapper ZIP.
3. Verify `Elyra-unsigned.ipa` against `SHA256SUMS` and `ipa-report.json`.
4. Sign/re-sign using a legitimate certificate and appropriate provisioning profile. This target has no App Group or embedded share extension requirement.
5. Record installation and launch results separately from build validation.

No signed or installation-tested release is supplied at present. Installation does not grant system-container access. Local backup restoration is not device-system restoration.
