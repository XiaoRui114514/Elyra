# Compatibility

Minimum deployment target: iOS/iPadOS 17. The universal target uses the same feature catalog and transaction layer on iPhone and iPad.

| Layer | iOS/iPadOS 26 | iOS/iPadOS 27 |
| --- | --- | --- |
| Build | Xcode 26.3 / SDK 26.2 pipeline | No SDK 27 build verification |
| UI runtime | 26.2 simulator qualification per source SHA; see TEST_REPORT | Unverified |
| Local data tools | Linux/macOS core tests; selected simulator UI flows | Device runtime unverified |
| System configuration | Native module includes 26 access modes; actual signed group + file permission probe required; physical behavior unverified | Native module includes 27 access modes; actual signed group + file permission probe required; physical behavior unverified |
| Allowed writes | Capability fields and documented artwork members; protected identity/binary fields rejected | Same policy; no universal build-support claim |
| Respring | Manual experimental WebKit action; unverified on physical hardware | Same; not an API support guarantee |
| System Dynamic Island geometry | No verified modification | No verified modification |

Support states distinguish supported, partial, experimental, additional conditions, unsupported system, unsupported hardware and unverified. A capability flag does not establish hardware or service availability. Each physical build needs independent access, identity, backup, write/readback, effect and restoration evidence.

When direct file permission is absent, signing must include an App Group actually permitted by the provisioning profile. The default identifier is `group.org.elyra.Elyra`; a signer may consistently replace it. An entitlement file or unsigned IPA alone grants no system access. Backups captured on connection are current device values, not factory originals.
