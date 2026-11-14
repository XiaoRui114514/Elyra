# Known issues

- System MobileGestalt access and system appearance changes are not implemented. Local edits and restores affect imported copies only.
- Forced Dynamic Island on iPad can have irregular proportions, positioning and corners across activities. No system-wide geometry fix has been verified.
- An imported baseline may already contain modifications. SHA-256 validates integrity, not device ownership or factory provenance.
- System wallpaper installation, dialer/launch-image replacement, notification codec/capture, native pairing, share extension and full directory browsing remain incomplete; see FEATURE_MATRIX.
- Document/text commits have recovery journals. Initial imports and Trash moves can leave orphaned files after abrupt interruption; no cross-process lock or power-loss certification.
- Staged plist drafts persist. Unstaged text, disclosure and scroll positions are not fully retained. Backup retention/deletion controls are pending.
- Classic ZIP limits: 64 MB compressed, 2,000 entries, 32 MB per entry, 128 MB expanded. ZIP64, encryption, multidisk and unsupported filename encodings are rejected. Descriptor names do not establish provider validity.
- UTF-8 editing is limited to 1 MB; binary/NUL text is rejected. File-version restoration has confirmation but no binary diff.
- Native system pickers/Quick Look/system errors may follow the OS language. Licenses and raw diagnostic data remain in their original language.
- Current Apple CI uses Xcode 26.3 and 26.2 simulators. iOS/iPadOS 27 runtime, physical installation, system effects, continuous Stage Manager resizing, external displays, VoiceOver and multiwindow UI acceptance remain unverified.

Unsupported mechanisms include management-policy edits, guessed cache offsets or subtype defaults, hardware identity spoofing, destructive cache resets and resource-exhaustion respring.
