# 0.3 signing requirements

The system-access build requires a usable **App Group in the actual provisioning profile and signature** when ordinary file access is denied. `group.org.elyra.Elyra` is the project default; re-signers may substitute a group provisioned for their own team. Runtime detection reads the effective signed groups and verifies that a container is usable. A text entitlement file alone does not grant access. Free-team signing services may not provide App Groups.

CI remains unsigned and exports `Elyra.entitlements` beside the IPA for signing configuration. Register the bundle/group under the signing team or let a capable signing tool replace identifiers consistently. File read/write probes remain decisive on each OS build. No certificate or provisioning profile is bundled. Simulator tests never invoke the access module or experimental Respring.

# Installation

GitHub Actions generates a genuine arm64 `Payload/Elyra.app` and packages it as an unsigned IPA. The exact qualified build, checksum and download link are recorded in TEST_REPORT.md.

Qualified build: **0.3.0 (18)**, [source tag](https://github.com/XiaoRui114514/Elyra/tree/v0.3.0-dev), [unsigned artifact](https://github.com/XiaoRui114514/Elyra/releases/download/v0.3.0-dev/Elyra-unsigned.ipa). SHA-256: `ee171a77bc4254da198e08653a16e7ddf062a566f50560211db307c9fc291487`.

1. Open the [0.3 development release](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.3.0-dev) or use its [direct IPA download](https://github.com/XiaoRui114514/Elyra/releases/download/v0.3.0-dev/Elyra-unsigned.ipa). These published release attachments do not require GitHub sign-in.
2. Download `Elyra-unsigned.ipa`, `SHA256SUMS`, `ipa-report.json` and, for system access signing, `Elyra.entitlements` from that release.
3. Verify the IPA against `SHA256SUMS` and `ipa-report.json`.
4. Sign/re-sign using a legitimate certificate and appropriate provisioning profile. For system access, provision a usable App Group and include the matching entitlement in the signature. There is no embedded share extension.
5. Record installation and launch results separately from build validation.

Actions artifacts remain available as build evidence but require GitHub sign-in; a signed-out browser may receive HTTP 404. They are wrapper ZIPs and must be extracted before using the IPA. Public release downloads return the IPA itself, so no wrapper extraction is needed.

No signed or installation-tested release is supplied at present. Successful installation alone does not establish access: connect through System → Device configuration and review the actual permission result. Local-document backups and directly captured device backups are separate.
