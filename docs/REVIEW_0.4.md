# 0.4 implementation review

Read-only review compared Elyra's 0.4 candidate with pinned Erosion and GestaltX implementations, including the refreshed upstream HEADs in UPSTREAM_RECHECK_0.4.md. No tests were executed during the review; qualification follows the second implementation pass.

## Selected work

1. Restore Dynamic Island's recorded flag and ArtworkDeviceSubType together, preserving other Artwork members. Reuse DynamicIslandEngine.restoringRecordedFields; upstream reference: GestaltX/Capabilities.swift, DI restoration branch.
2. Preserve existing Boolean types for binary capability presets. Counts, arrays and device-specific Siri retain separate validation.
3. Device backups: verified offline inspection/export, optional comparison with the current capture, and separately gated device restoration. Reference: GestaltX/GestaltDocument.swift backup/export validation. Imported exports do not establish device trust.
4. Reusable configuration plans: versioned JSON containing only known capability IDs and apply/restore actions; no device original values or identity. Merge against one live snapshot, detect overlapping conflicting field intents, review one difference set and commit through one backup/write transaction. Reference: GestaltX/GestaltManager.swift's combined choices preview; reusable data-only plan format is new to these reviewed sources.
5. Window and display diagnostics: current UIWindowScene's window/content size, safe areas, scale, pixel bounds, maximum refresh capability and EDR headroom. Optional CADisplayLink measurement reports this application's callbacks only. No privileged access or system changes.
6. Recovery/editing fixes: reject valid unexpected recovery contents rather than overwrite external edits; retain a recovery scene copy for partial writes; make expired editor sessions reconnectable without discarding drafts; reuse identical live working copies and cache unchanged field indexes; scope UI-test back actions to the detail navigation bar.

## Public API references

- https://developer.apple.com/documentation/uikit/uiwindowscene/screen (iOS 13+)
- https://developer.apple.com/documentation/uikit/uiscreen/maximumframespersecond (iOS 10.3+)
- https://developer.apple.com/documentation/uikit/uiscreen/currentedrheadroom (iOS 16+)
- https://developer.apple.com/documentation/uikit/uiscreen/potentialedrheadroom (iOS 16+)
- https://developer.apple.com/documentation/quartzcore/cadisplaylink/timestamp

EDR headroom is not panel peak luminance; callback rate is not panel scan rate or PWM. No global novelty claim is made.

## Subsequent migration

User-selected directory browsing can use a security-scoped folder picker, bookmarks and NSFileCoordinator; reference: Erosion/FileManager/Browser/FileBrowserView.swift. Audio conversion and image sizing can use AVAudioConverter and ImageIO/UIKit; references: GestaltX/AppSoundCodec.swift and Erosion/Tweaks/Keypads/KeypadManager.swift. These local tools do not imply system sound/keypad installation. PosterBoard, cross-app replacement and Rust pairing need separate access and recovery work.

Primary pages retain concise controls. Detailed explanations remain optional; actual failures retain concrete messages. No personal device details or reference screenshots are distributed.
