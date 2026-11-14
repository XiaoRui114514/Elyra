# Compatibility

Minimum deployment target: iOS/iPadOS 17. The universal target uses the same feature catalog and transaction layer on iPhone and iPad.

| Layer | iOS/iPadOS 26 | iOS/iPadOS 27 |
| --- | --- | --- |
| Build | Xcode 26.3 / SDK 26.2 pipeline | No SDK 27 build verification |
| UI runtime | 26.2 simulator matrix; exact candidate results in TEST_REPORT | Unverified |
| Local data tools | Linux/macOS core tests; selected simulator UI flows | Device runtime unverified |
| System configuration | No access backend | No access backend |
| System Dynamic Island geometry | No verified modification | No verified modification |

Support states distinguish supported, partial, experimental, additional conditions, unsupported system, unsupported hardware and unverified. A capability flag does not establish hardware or service availability. Each physical build needs independent access, identity, backup, write/readback, effect and restoration evidence.
