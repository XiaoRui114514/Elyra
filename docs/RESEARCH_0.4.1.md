# Device preferences and Apple Intelligence — 0.4.1

Reviewed on 2026-11-15 UTC. Erosion HEAD: `fb16225faa120d258ca5b8856568cf504199598f`; its MobileGestalt code is unchanged from pinned `12c0a2d00c444c9b09112608b47d4d6c10e0df14`. The new commit changes file-browser/container handling. GestaltX HEAD remains `72bf625befdb5e9e16d52c663e123f9fbc8ec7bf`, with native/capability code unchanged from pinned `d1d5473734440e8f2e797494ac373427c02fd674`. Vendored native modules remain pinned; no unrelated access change is imported.

## Sources and resulting choices

- [GestaltX Capabilities.swift](https://github.com/huamidev/GestaltX/blob/d1d5473734440e8f2e797494ac373427c02fd674/GestaltX/Capabilities.swift): On-Device Siri deliberately lacks a generic enable choice. Preserve its device-specific type; enable the other seven intelligence presets together.
- [GestaltX GestaltManager.swift](https://github.com/huamidev/GestaltX/blob/d1d5473734440e8f2e797494ac373427c02fd674/GestaltX/GestaltManager.swift): model naming synchronizes ArtworkDeviceProductDescription plus `Z/dqyWS6OZTRy10UcmUAhw` and `bbtR9jQx50Fv5Af/affNtA`. Elyra now uses the same field set, preserving unrelated artwork.
- [GestaltX README](https://github.com/huamidev/GestaltX/blob/72bf625befdb5e9e16d52c663e123f9fbc8ec7bf/README.md): RegionCode and Sales Region are separate. The combined recipe sets RegionCode to LL and retains both sales suffixes. Erosion's older region toggle also changes a sales suffix; that broader change is not required by this recipe.
- [Nugget upstream](https://github.com/leminlimez/Nugget): its documented version/access constraints differ from this on-device backend. Older AI-enabler instructions do not qualify current builds.
- [Apple requirements](https://support.apple.com/en-us/121115): hardware, language, account, region, downloads and service eligibility are separate from local capability flags. A verified cache write is not service activation.
- [MobileGestalt key reference](https://theapplewiki.com/wiki/List_of_MobileGestalt_keys): useful for identifying fields; it does not establish write permission or current Settings behavior.

Public X research found [huami's release post](https://x.com/huami_1214/status/2119664852105113921), readable through [its post mirror](https://zamantika.com/ar/huami_1214/status/2119664852105113921): region-code changes preserve the sales suffix and signing needs an App Group. [Suversal's post](https://x.com/suversal/status/2119767348316106971), readable through [its mirror](https://zamantika.com/ar/suversal/status/2119767348316106971), describes choosing LL while keeping Sales Region. Direct X requests returned HTTP 403, so these are explicitly mirror-based observations, cross-checked with pinned source rather than presented as direct X retrieval or Elyra device tests. Initial handle-specific searches returned no results; broader Chinese searches resolved these posts. eSIM claims and unrelated mainland-Mac methods are outside this recipe. Community posts are not peer-reviewed papers.

## General → About

| Item | Finding | 0.4.1 |
| --- | --- | --- |
| Model Name | Three source-confirmed display fields; distinct from ProductType/board/CPU identity | Real captured-cache edit, differences, backup/readback and targeted restoration implemented; actual Settings rendering needs device validation |
| Model Number | Retail ModelNumber uses `D0cJ8r7U5zve6uA6QbOiLA`; hardware RegulatoryModelNumber uses `97JDvERpVwO+GHtthIh7hA` | Do not confuse the two. GestaltX's A-number preset edits the latter. Neither is exposed as a verified About customization in this build |
| iPadOS/iOS Version | ProductVersion has a query/cache key; installed OS version also has system-owned sources | No evidence that this fixed-cache writer can reliably change About. A cache value is not an OS upgrade/downgrade; no unsupported SystemVersion.plist write or Settings-process patch is added |
| Serial Number | The key is known; GestaltX explicitly preserves actual serial/UDID/chip fields | Remains protected. Editing a reported cache value cannot alter the hardware serial |
| Capacity / Available | Filesystem/hardware storage measurements; battery-capacity tweaks are a different quantity | No verified About override in either reviewed base implementation; no capacity-change claim or arbitrary binary-cache offsets |

A separately privileged Settings-process customization could affect displayed text on some modified systems, but that is not supplied or validated by the current signed-App-Group MobileGestalt path. No app-only About mockup is presented as a Settings modification.

## Transactions and compatibility

The intelligence recipe uses one live snapshot and one confirmed transaction. Device-specific Siri and sales suffixes are unchanged; the reviewed difference list shows actual writes. Model names are trimmed and limited to 256 UTF-8 bytes, without control characters. Both recipes restore only their own fields from a verified initial capture, retaining other edits.

Backup records now carry a generation policy version. The original capability-field set is frozen in LegacySystemPolicy rather than derived from a growing catalog. Older records validate their original policy/hash first, then compare a normalized generation under the current allowlist; their bytes and initial-capture provenance are retained. Corrupt originals never become replacement baselines. Serial/UDID/board/CPU and binary CacheData remain protected.

Neither iOS/iPadOS 26 nor 27 receives a blanket service/visual-effects guarantee. Actual permissions and physical rendering must be checked per build. See TEST_REPORT for app-level qualification.
