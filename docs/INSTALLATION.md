# 0.3 signing requirements

The system-access build requires a usable **App Group in the actual provisioning profile and signature** when ordinary file access is denied. `group.org.elyra.Elyra` is the project default; re-signers may substitute a group provisioned for their own team. Runtime detection reads the effective signed groups and verifies that a container is usable. A text entitlement file alone does not grant access. Free-team signing services may not provide App Groups.

CI remains unsigned and exports `Elyra.entitlements` beside the IPA for signing configuration. Register the bundle/group under the signing team or let a capable signing tool replace identifiers consistently. File read/write probes remain decisive on each OS build. No certificate or provisioning profile is bundled. Simulator tests never invoke the access module or experimental Respring.

# Installation

GitHub Actions generates a genuine arm64 `Payload/Elyra.app` and packages it as an unsigned IPA. The exact qualified build, checksum and download link are recorded in TEST_REPORT.md.

Qualified build: **0.2.0 (10)**, [source tag](https://github.com/XiaoRui114514/Elyra/tree/v0.2.0-dev), [unsigned artifact](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290/artifacts/14112913746). SHA-256: `a47c784cbcc27b6c64a40835586a9e6d38000d2c0ed99fca6be25e846874df55`.

1. Choose a completely successful run in [Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml).
2. Download `Elyra-unsigned-<source SHA>` and extract the artifact wrapper ZIP.
3. Verify `Elyra-unsigned.ipa` against `SHA256SUMS` and `ipa-report.json`.
4. Sign/re-sign using a legitimate certificate and appropriate provisioning profile. For system access, provision a usable App Group and include the matching entitlement in the signature. There is no embedded share extension.
5. Record installation and launch results separately from build validation.

No signed or installation-tested release is supplied at present. Successful installation alone does not establish access: connect through System → Device configuration and review the actual permission result. Local-document backups and directly captured device backups are separate.
