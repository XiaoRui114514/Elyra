# Installation

Elyra 0.4.2 (29) supplies a real arm64 `Payload/Elyra.app` in two packages:

| Package | Signature | Use |
| --- | --- | --- |
| `Elyra-resignable.ipa` | Ad-hoc, with embedded App Group template | Recommended input for a capable re-signing tool |
| `Elyra-unsigned.ipa` | None | Manual signing with explicit entitlement configuration |

Both require a legitimate certificate and provisioning profile before installation. Neither is an installation-tested, certificate-signed release. The ad-hoc template helps signing tools discover requested groups; it does not grant permissions.

1. Open the [0.4.2 development release](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.4.2-dev) and download [Elyra-resignable.ipa](https://github.com/XiaoRui114514/Elyra/releases/download/v0.4.2-dev/Elyra-resignable.ipa).
2. Verify its SHA-256 against `SHA256SUMS` and `resignable-ipa-report.json` from the release.
3. Re-sign with an appropriate certificate/profile. When ordinary file access is denied, system access needs an App Group permitted by the final provisioning profile and signature. `group.org.elyra.Elyra` is the template; a signer may replace it consistently with its own provisioned group. A text entitlement file or a locally selected flag cannot grant access. Some signing services do not supply App Groups.
4. Install and launch. Open System: Elyra automatically checks actual read/write permission. An eligible feature exposes **Modify → Apply preset → Review device changes → Confirm & apply**. Restore captured value uses recorded device data. Failed checks retain a concrete connection error and a retry control.
5. Record installation, actual write/readback, feature effect and restoration separately. A successful file write does not establish a hardware feature or Apple service.

Release attachments download anonymously and return the IPA itself. Actions artifacts require GitHub sign-in, may return 404 while signed out, and contain wrapper ZIPs that must be extracted. Do not rename a wrapper ZIP to IPA.

No share extension is embedded. Local documents and directly captured device backups remain separate. Source identity, tests, hashes and unverified physical behavior are recorded in [TEST_REPORT](TEST_REPORT.md).

## Device preferences

System → Intelligence → Apple Intelligence for China Mainland prepares seven capability flags plus RegionCode LL. Review and confirm, then restart the device and check Apple Intelligence & Siri in Settings. Sales-region suffixes and the device-specific Siri value are retained. System service availability is separate from verified cache writing.

System → Device → Change Model Name synchronizes three display fields. Review before applying; restart if Settings still shows cached text. Restore captured value affects only those name fields. Other General → About items remain research; see RESEARCH_0.4.1.md.

In 0.4.2 the model-name entry shares the Device grid. Tap the field or Edit to enter a name; Done dismisses the software keyboard. Returning to the editor retains the scene draft. A successful apply/restore refreshes the field from the verified device snapshot. System → Intelligence → Region code changes only the selected raw code; review its differences and use Restore captured value to recover the recorded original.
