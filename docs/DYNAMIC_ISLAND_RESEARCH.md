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

The Dynamic Island page inspects imported capability/artwork fields and offers staged, confirmed local changes. A separate Device configuration connection captures the live cache and can write allowlisted capability/artwork changes after confirmation and actual access checks. Targeted restoration uses that document's verified imported baseline and preserves unrelated members and absence/type semantics. A baseline may already be modified; it is not authenticated factory data.

Appearance records cover idle, recording, timer, call, navigation, media and multiple activities, including corner, shape, proportion and position outcomes. Playback state is optional and omitted for non-media records. Simulator attribution is automatic. A separately labeled appearance preview is illustrative only.

The device writer creates verified, installation-bound backups and can restore captured bytes after inode/revision/generation checks. This restores a recorded configuration, which may already contain modifications. Native access and system transactions are implemented; physical results remain unverified. No system geometry repair has been established, and no radius/animation parameter is offered.

## References

- [Apple: Design dynamic Live Activities](https://developer.apple.com/videos/play/wwdc2023/10194/): compact, expanded and minimal presentations, concentric content and distinct activity behavior.
- [Apple: Live Activities essentials](https://developer.apple.com/videos/play/wwdc2026/223/): iOS 27 landscape and limited-width handling.
- [Apple: isDynamicIslandLimitedInWidth](https://developer.apple.com/documentation/swiftui/environmentvalues/isdynamicislandlimitedinwidth): a read-only environment value for an app's own content.
- [Apple: displaying Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities): system-controlled presentation.
- [misakaX #53](https://github.com/straight-tamago/misakaX/issues/53), [#285](https://github.com/straight-tamago/misakaX/issues/285), [Nugget #834](https://github.com/leminlimez/Nugget/issues/834): historical iPad shape/orientation reports, without a verified current universal fix.

Community reports and older private-rendering experiments do not establish current OS behavior. No guessed radius, identity patch or internal rendering layer is applied by Elyra.

## Screen-corner hypothesis — 2026-11-15

A screen-corner metric is a concrete research lead, but there is no established one-to-one identity between physical screen rounding and every Dynamic Island presentation. Distinguish the display metric, the activity container's layout radius and its rendering/mask. No individual device details are included here.

| Evidence | What it establishes | Limit |
| --- | --- | --- |
| [Current Apple Live Activities guidance](https://developer.apple.com/design/human-interface-guidelines/live-activities.md) | Compact, minimal and expanded presentations are distinct; content should use the container's relative shape | No system-wide screen-radius override is provided; older mirrored numeric design guidance is not a runtime setting |
| [iOS 26 community disassembly, fixed commit](https://github.com/samhenrigold/SpringBoard_Disassembly-26.0_23A343/blob/560125cff6c218f04b790a9067c6469d67a3be2c/SBSAPlatformMetricsContext.m) | The System Aperture metrics context contains `displayCornerRadius` and separate square/oval/tall-rectangle corner fields | Decompiled names/types and aliases are incomplete; they do not establish exact consumers or defaults on iPadOS 27 |
| [Metrics mutator](https://github.com/samhenrigold/SpringBoard_Disassembly-26.0_23A343/blob/560125cff6c218f04b790a9067c6469d67a3be2c/SBSAPlatformMetricsContextMutator.m), [settings](https://github.com/samhenrigold/SpringBoard_Disassembly-26.0_23A343/blob/560125cff6c218f04b790a9067c6469d67a3be2c/SBSystemApertureSettings.h) | Related symbols include `customLayoutTallRectCornerRadius`, `maximumCornerRadius` and `tallRectCornerRadius` | These are private runtime/settings symbols, not verified MobileGestalt keys or a documented writable preferences format |
| [NotchSimulator, fixed source](https://github.com/SniperGER/NotchSimulator/blob/3a00cfcb6122c6abe32c06c636825e1a6b4ebf33/Tweak.xm) | An older injected tweak overrides `UIScreen._displayCornerRadius` and a trait radius separately from screen bounds | Predates Dynamic Island. It proves an old runtime-hook technique, not a working iPadOS 26/27 remedy |
| [Community report](https://www.reddit.com/r/iOS27/comments/1vfobts/ios27bd4_bug_dynamic_island/) | A commenter associates forced islands on square-corner phones with square presentation | Anecdotal and not a controlled iPad experiment |
| [Jinwoo Kim rendering study](https://pookjw.github.io/Develop/About_CAGainMapLayer/article.html) | Earlier island rendering involved private gain-map layers and device-dependent behavior | iOS 16-era findings; its black-screen/compatibility limitations make it unsuitable as an unvalidated fix |

### Can another model's screen geometry be advertised without other changes?

Overriding a radius getter need not change framebuffer resolution, but a global display/trait override can also change other system UI, clipping and safe-area-dependent behavior. Changing ProductType or ArtworkDeviceSubType selects broader identity/layout behavior and cannot guarantee an unchanged normal display. A more focused route would change only the aperture container's relevant radius/metrics; the separate fields above make this worth investigating, not proven operational.

The current backend reads/writes a fixed MobileGestalt cache. It cannot by itself replace SpringBoard methods or establish a working setter/IPC path for these runtime objects. Known older examples use privileged process injection. No guessed `DeviceCornerRadius`, `displayCornerRadius` or `customLayoutTallRectCornerRadius` key is written into CacheExtra, and no model-substitution preset is labeled as an appearance repair.

### Next validation

1. On an authorized physical test device/build, read the effective screen radius and aperture metrics without changing identity, resolution, scale or safe areas.
2. Trace the actual compact/minimal/expanded consumers, including the vertical tall-rectangle branch, and verify whether their radius derives from screen radius, an inset, a maximum or a state-specific override.
3. Establish a scoped, reversible control path before trying any value. Verify window bounds, orientation, touch alignment, safe areas, display scale, notifications and app switching as well as all activity states.
4. Preserve exact originals and readback. Simulator-only measurements, API names and in-app rendering cannot qualify a system repair.

Status: additional technical leads found; screen-radius equality and a radius-only, normal-display-preserving system modification remain unverified. The 0.4.1 app does not include a claimed corner-radius repair.
