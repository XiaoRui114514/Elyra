# iPad Dynamic Island appearance and layout

## Scope

Forced Dynamic Island on iPad can have unnatural corners, proportions or positioning across idle and active states. Media playback is one example; recording, timers, calls, navigation and multiple activities require separate checks. No system-wide appearance correction has been verified.

Reference images show a narrow, vertically stretched capsule near the screen edge. In the media example, album art is near one end and the waveform near the other, with a large gap. A separate recording indicator is also visible. Notification banners are a different system surface. Reference images and individual device details are not distributed in this repository.

## Source-confirmed controls

| Configuration | Evidence | Scope |
| --- | --- | --- |
| `YlEtTtHlNesRBMal1CqRaA` | Erosion MGKey.island; GestaltX dynamicIsland preset | Dynamic Island capability declaration |
| `oPeik/9e8lQWMszEjbPzng` → `ArtworkDeviceSubType` | Both artwork editors | Device artwork/layout identity; not pixel width or corner radius |
| Artwork device name | Both artwork editors | Independent dictionary member; preserve other artwork fields |
| DeviceClass/ProductType/CacheData | Upstream identity/cache modules | Broader system identity; no verified appearance correction |

Pinned source identities and implementation locations are in SOURCE_AUDIT.md. Upstream presets differ, including 2436 versus 2556 for similarly labeled phone layouts. No value is established as a universal iPad correction. No independent system capsule radius, content placement or animation parameter was found in these implementations.

Orientation/artwork identity mismatch is a plausible hypothesis, not a confirmed root cause. Public ActivityKit APIs supply an app's own activity content within system-selected presentations; they do not control other apps' activities or SpringBoard geometry.

## State matrix

| State | Evidence and required validation |
| --- | --- |
| Idle / no media | Shape and corner reports; verify after clearing all activities |
| Compact and expanded media | Reference images cover compact media; expansion and play/pause transitions need separate tests |
| Recording / timer / call / navigation | Evaluate each activity's minimal, compact and expanded forms independently |
| Multiple activities | Reference shows separate recording/media regions; compare with single-activity states |
| Portrait / landscape | Record full display, orientation lock, scaling and transition behavior |

A test result needs exact system build, independently verified configuration lineage, before/after differences, file readback, full-state observation and restoration results. Compilation or a simulator image is insufficient.

## Product implementation

The Dynamic Island page inspects imported capability/artwork fields and offers staged, confirmed local changes. Targeted restoration uses that document's verified imported baseline and preserves unrelated members and absence/type semantics. A baseline may already be modified; it is not authenticated factory data.

Appearance records cover idle, recording, timer, call, navigation, media and multiple activities, including corner, shape, proportion and position outcomes. Playback state is optional and omitted for non-media records. Simulator attribution is automatic. A separately labeled appearance preview is illustrative only.

A system recovery path requires supported authorized access and trusted same-device original data. Neither system writing nor system geometry repair is implemented.

## References

- [Apple: Design dynamic Live Activities](https://developer.apple.com/videos/play/wwdc2023/10194/): compact, expanded and minimal presentations, concentric content and distinct activity behavior.
- [Apple: Live Activities essentials](https://developer.apple.com/videos/play/wwdc2026/223/): iOS 27 landscape and limited-width handling.
- [Apple: isDynamicIslandLimitedInWidth](https://developer.apple.com/documentation/swiftui/environmentvalues/isdynamicislandlimitedinwidth): a read-only environment value for an app's own content.
- [Apple: displaying Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities): system-controlled presentation.
- [misakaX #53](https://github.com/straight-tamago/misakaX/issues/53), [#285](https://github.com/straight-tamago/misakaX/issues/285), [Nugget #834](https://github.com/leminlimez/Nugget/issues/834): historical iPad shape/orientation reports, without a verified current universal fix.

Community reports and older private-rendering experiments do not establish current OS behavior. No guessed radius, identity patch or internal rendering layer is applied by Elyra.
