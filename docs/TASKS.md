# 0.4.2 qualification

- [x] Separate scene-window navigation geometry from keyboard avoidance; share the window probe with diagnostics.
- [x] Model-name Edit/Done, scene draft retention, verified-value refresh and shared sorted device grid.
- [x] Rechecked pinned upstream region presets; added independent bounded RegionCode selection/restoration without changing sales suffixes or Siri types.
- [x] Shortened intelligence detail title; retained complete category entry label.
- [x] Qualified source `8bcdb02cc1b5b4f56969e354405ac9a471aa6866`, run 43707797116: 105 core, 14 Python, 11 UI scenarios per simulator; all three jobs passed first attempt, with analysis/archive and independently verified build-29 IPAs.
- [ ] Publish verified development IPA assets and check anonymous downloads.
- [ ] Physical keyboard/input, Settings rendering and per-build system-effect acceptance; continuous Stage Manager resize remains pending.

Research and bounded follow-up candidates: [RESEARCH_0.4.2.md](RESEARCH_0.4.2.md). Historical records follow.

# 0.4.1 delivery

- [x] Rechecked upstream sources, developer/community X posts and key references; RESEARCH_0.4.1.md records evidence and limits.
- [x] Mainland intelligence recipe: seven supported flags + RegionCode LL, reviewed single transaction, sales region and device-specific Siri preserved.
- [x] Three-field model-name editor and captured-value restore.
- [x] Actual on/off/partial/unknown states, enabled-card checks and explicit enable/disable actions.
- [x] Frozen legacy backup policy; older captures remain usable; disabling Dynamic Island restores its captured subtype.
- [x] Public v0.4.1-dev release; guarded workflow and both anonymous IPA download/hash checks passed.
- [x] VERSION = 0.4.1; patch-only future numbering. 625 localization keys and 104 matrix rows.
- [x] Qualified source `94942ddebc8ae60474be8bb10620e8f503420ebb`, [run 43680976089](https://github.com/XiaoRui114514/Elyra/actions/runs/43680976089): 102 core, 14 Python, nine UI scenarios on each simulator, Xcode analysis/archive and independently verified build-28 IPAs. No UI retry was required.
- [x] Expanded screen-radius research: separate aperture metrics identified, older scoped/global hook evidence recorded, no unverified geometry write added.
- [ ] Physical signing, About rendering, service activation, per-build system writes/restoration and radius-only SpringBoard control validation.

Continuous window resize, external displays, VoiceOver, multiwindow UI and remaining appearance/file/pairing modules remain pending. Existing source and native modules retain their license notices. Long native navigation titles can ellipsize; shorten the intelligence detail title in a future patch while keeping the entry's full name.

Historical records follow.

# 0.4 delivery

- [x] Independent source review and second implementation pass; decisions and API evidence in REVIEW_0.4.md.
- [x] Adaptive System tiles throughout dashboard/categories/features; direct Modify actions; separate navigation per area; explicit sidebar actions after relaunch.
- [x] Automatic real access checks and embedded App Group template in the re-signable IPA.
- [x] Recorded Dynamic Island flag/subtype restoration, Boolean preservation, offline backup inspection/export and reusable configuration plans.
- [x] Current-window/display diagnostics, draft rebase/reconnect, external recovery-conflict protection, working-copy reuse and cached field indexes.
- [x] Concise primary controls and 607 matching bilingual entries.
- [x] Exact code source `b1e85e16a8c3195919fc4bc0ec5d33d4689a21f7`: [run 43676397713](https://github.com/XiaoRui114514/Elyra/actions/runs/43676397713) passes 93 core tests, 14 Python checks, analysis/archive and eight UI scenarios per simulator. The iPad task was rerun after a Simulator launch-progress timeout; source was unchanged.
- [x] Public `v0.4.0-dev` prerelease, guarded release workflow and anonymous download/hash verification.
- [x] Build 26 re-signable and unsigned arm64 IPAs independently verified. Installation and physical system effects remain unverified.
- [ ] Legitimate signing and physical read/write/restore/Respring acceptance; continuous Stage Manager resize, external display, VoiceOver and multiwindow UI acceptance.

Source, package hashes and per-attempt evidence: TEST_REPORT.md. Next implementation: selected-directory access, local audio/image processing, PosterBoard installation, pairing and device operation-history integration. No verified system Dynamic Island geometry repair is available.

The 0.3 record below is historical.

# Development status

## 0.3 delivery

- [x] Pinned native access modules, effective signed-App-Group discovery and actual descriptor permission probes.
- [x] Live-cache sessions, allowlisted capability/artwork writes, installation-bound device backups, revision/inode checks, confirmation, exact readback, rollback and explicit interrupted-write recovery.
- [x] Shared local/device editing engine; external imports cannot create a device session.
- [x] Removed Home quick access and special Dynamic Island placement; added manually confirmed experimental Respring.
- [x] Redesigned adaptive System categories and direct About account cards with official app icons, brand accents and a separate legal page.
- [x] English, Simplified Chinese and Follow System; 523 matching localized entries.
- [x] Portable validation: 76 Swift core tests, 8 Python negative tests, repository/workflow checks.
- [x] Apple qualification for source `b0f2232d3ff989cfae673dce94241dc4eebd563e`, [run 43617128024](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024): analysis, both five-scenario UI jobs, Release archive and downloaded IPA verification. Version 0.3.0 (18), unsigned.
- [x] Guarded release workflow 43618402178; v0.3.0-dev is a public development prerelease with four verified build assets; direct anonymous IPA download is verified.
- [ ] Legitimate signing, physical installation and per-build read/write/restore/Respring validation.

## Remaining implementation

1. Physical acceptance of device backup export/restoration and device operation-history integration; backup export and single-preset restoration are implemented in 0.4.
2. Bounded wallpaper-provider installation, dialer and launch-image processing/replacement, notification audio codec/capture and share-extension handoff. These are not supplied by the MobileGestalt writer.
3. Independently reviewed native pairing and selected-directory browsing; no management-policy edits or guessed binary offsets.
4. UI coverage for imports, text editing, archives and backup restoration; retained text drafts, scroll/focus state and backup retention.
5. Continuous Stage Manager resize, external displays, VoiceOver and simultaneous multiwindow language/UI acceptance.
6. Dynamic Island appearance research across all activity states and orientations. No verified system radius, layout or animation repair is available.
7. Native App Group temporary-cache cleanup under abrupt termination; this remains outside the system-write recovery journal.

## Continuing development

Read AGENTS.md, FEATURE_MATRIX.md, TEST_REPORT.md and KNOWN_ISSUES.md. Keep code qualification bound to a successful exact source SHA. Documentation-only changes do not qualify new app code. Keep documentation technical and impersonal; retain mandatory license notices. Never treat an imported or captured modified configuration as a factory original.

Core checks: `swift test`; `python3 -m unittest discover -s Tests -p 'test_*.py'`; `python3 scripts/check_repository.py`. Generate the Xcode project and localization resources reproducibly. Apple builds/UI tests/archive run through Actions; physical system effects require separate evidence.
