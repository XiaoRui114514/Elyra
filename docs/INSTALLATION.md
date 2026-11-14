# Installation

GitHub Actions generates a genuine arm64 `Payload/Elyra.app` and packages it as an unsigned IPA. The exact qualified build, checksum and download link are recorded in TEST_REPORT.md.

1. Choose a completely successful run in [Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml).
2. Download `Elyra-unsigned-<source SHA>` and extract the artifact wrapper ZIP.
3. Verify `Elyra-unsigned.ipa` against `SHA256SUMS` and `ipa-report.json`.
4. Sign/re-sign using a legitimate certificate and appropriate provisioning profile. This target has no App Group or embedded share extension requirement.
5. Record installation and launch results separately from build validation.

No signed or installation-tested release is supplied at present. Installation does not grant system-container access. Local backup restoration is not device-system restoration.
