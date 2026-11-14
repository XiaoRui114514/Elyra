# Development status

## Implemented

- Universal SwiftUI project, five navigation areas, window-size layout policy and shared transaction actor.
- Typed plist import/export, nested editing/search, drafts, differences, verified backups and recovery.
- Dynamic Island field inspection, local baseline restoration and appearance observations across activity types.
- UTF-8 editing with file-version backups, ZIP/tendies inspection, previews and operation-log export.
- Persistent English/Simplified Chinese/Follow System selection with shared localization state.
- GitHub Actions analysis, core/UI tests, device archive, IPA validation and guarded draft release.

Latest source qualification and artifacts are recorded in TEST_REPORT.md. This is a local-tool development release; system integration remains incomplete.

## Remaining work

1. Complete the current Apple CI run and keep source/artifact hashes bound to that run.
2. Add UI coverage for import, text editing, archive export and backup restoration.
3. Validate continuous Stage Manager resizing, external display, VoiceOver and simultaneous multiwindow language changes.
4. Add user-selected directory browsing, retained text drafts, scroll/focus persistence and backup retention.
5. Implement bounded wallpaper-provider parsing, image/audio processing and share-extension handoff.
6. Review native pairing independently. System writes require a supported access mechanism, device identity, trusted originals and verified recovery; pairing alone is insufficient.
7. Continue iPad Dynamic Island shape/layout research across idle and all activity states. No verified system geometry control is available.

## Checks

`swift test`; `python3 -m unittest discover -s Tests -p 'test_*.py'`; `python3 scripts/check_repository.py`. Project and localization generation must remain reproducible. Audit scripts use the separately pinned upstream repositories.
