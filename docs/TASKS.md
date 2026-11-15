# 0.4 candidate — second implementation pass

Independent source review is complete: REVIEW_0.4.md records the chosen work and API evidence. Earlier candidate runs 43622633201 and 43623138805 were canceled before this pass, as requested. The review did not run tests or edit source.

Implemented: cohesive adaptive system tiles and independent area navigation; direct Modify actions; automatic access probing; recorded DI flag/subtype restoration; Boolean preservation; offline device backup inspection/comparison/export; saved/imported/exported multi-feature configuration plans; current-window/display/EDR diagnostics and optional application callback sampling; recovery-conflict protection; draft rebase/reconnect; working-copy reuse and cached field indexes. Generic explanations and the language footers are removed or folded into details.

Packaging supplies both unsigned and re-signable ad-hoc IPAs; actual signature entitlements, team absence and package structure are checked. Physical permissions and system effects are not established by ad-hoc signing.

Second-pass validation started only after review and implementation: 92 Linux Swift tests passed; Apple compile/UI/archive qualification is pending. Keep the public 0.3 release until the new exact source qualifies. Follow-up migration: selected directories, audio/image processing, PosterBoard installation and Rust pairing.

The 0.3 record below remains historical and does not qualify changed 0.4 code.

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

1. Device backup export, dedicated single-preset system restoration and device operation-history integration.
2. Bounded wallpaper-provider installation, dialer and launch-image processing/replacement, notification audio codec/capture and share-extension handoff. These are not supplied by the MobileGestalt writer.
3. Independently reviewed native pairing and selected-directory browsing; no management-policy edits or guessed binary offsets.
4. UI coverage for imports, text editing, archives and backup restoration; retained text drafts, scroll/focus state and backup retention.
5. Continuous Stage Manager resize, external displays, VoiceOver and simultaneous multiwindow language/UI acceptance.
6. Dynamic Island appearance research across all activity states and orientations. No verified system radius, layout or animation repair is available.
7. Native App Group temporary-cache cleanup under abrupt termination; this remains outside the system-write recovery journal.

## Continuing development

Read AGENTS.md, FEATURE_MATRIX.md, TEST_REPORT.md and KNOWN_ISSUES.md. Keep code qualification bound to a successful exact source SHA. Documentation-only changes do not qualify new app code. Keep documentation technical and impersonal; retain mandatory license notices. Never treat an imported or captured modified configuration as a factory original.

Core checks: `swift test`; `python3 -m unittest discover -s Tests -p 'test_*.py'`; `python3 scripts/check_repository.py`. Generate the Xcode project and localization resources reproducibly. Apple builds/UI tests/archive run through Actions; physical system effects require separate evidence.
