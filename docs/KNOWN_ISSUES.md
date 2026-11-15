# Known issues

- Native MobileGestalt access and a restricted capability/artwork writer are implemented. Actual access depends on the exact system build and a usable signed App Group when direct permission is absent. Physical writes, rollback, restoration and installation remain unverified.
- The upstream App Group cache-link helper restores its original directory during normal cleanup. Abrupt termination inside that native grant operation can leave a preserved `.GestaltX-Caches-*.backup` directory or temporary link. The system-write journal does not cover this step; no power-loss certification or automatic directory-repair claim is made.
- Home Respring uses an experimental upstream WebKit resource-pressure method. It is explicitly confirmed, can fail or interrupt apps, is disabled while operations/recovery are pending, and has not been triggered on physical hardware in this qualification.
- Forced Dynamic Island on iPad can have irregular proportions, positioning and corners across activities. No system-wide geometry fix has been verified.
- An imported baseline may already contain modifications. SHA-256 validates integrity, not device ownership or factory provenance.
- System wallpaper installation, dialer/launch-image replacement, notification codec/capture, native pairing, share extension and full directory browsing remain incomplete; see FEATURE_MATRIX.
- Document/text commits have recovery journals. Initial imports and Trash moves can leave orphaned files after abrupt interruption; no cross-process lock or power-loss certification.
- Configuration plans save known capability intent only. Their import/export does not transfer device trust or original cache values.
- Re-signable IPAs contain an ad-hoc App Group template; re-signers must provision a usable group in the final signature. Ad-hoc packaging alone does not grant system access.
- Staged plist drafts persist. Unstaged text, disclosure and scroll positions are not fully retained. Backup retention/deletion controls are pending.
- Classic ZIP limits: 64 MB compressed, 2,000 entries, 32 MB per entry, 128 MB expanded. ZIP64, encryption, multidisk and unsupported filename encodings are rejected. Descriptor names do not establish provider validity.
- UTF-8 editing is limited to 1 MB; binary/NUL text is rejected. File-version restoration has confirmation but no binary diff.
- Native system pickers/Quick Look/system errors may follow the OS language. Licenses and raw diagnostic data remain in their original language.
- Current Apple CI uses Xcode 26.3 and 26.2 simulators. iOS/iPadOS 27 runtime, physical installation, system effects, continuous Stage Manager resizing, external displays, VoiceOver and multiwindow UI acceptance remain unverified.

Excluded operations include management-policy edits, guessed cache offsets or subtype defaults, hardware identity spoofing and destructive cache resets. Device backup inspection/export and single-preset restoration are implemented in 0.4. Physical restore acceptance and device operation-history integration remain incomplete.

0.4.1 adds real display-name preferences and a combined intelligence/region recipe. Their system rendering and service activation still need physical validation. On-Device Siri is deliberately preserved. Retail/regulatory Model Number, Serial Number, OS Version and Capacity are not exposed as verified About overrides. Private aperture radius fields are research leads, not currently implemented controls. Long native English navigation titles can ellipsize; their complete label remains on the entry tile and in accessibility metadata.
