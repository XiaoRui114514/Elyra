# 0.3 candidate status

Implemented: native signed-App-Group access using pinned upstream modules, live-cache sessions, a restricted capability/artwork writer, device-bound backups, inode/revision checks, readback, rollback and explicit interrupted-write recovery. Home shortcuts and Dynamic Island pin removed; System overview redesigned; About has profile cards and a separate legal page; Respring is manual and experimental.

Validation: 76 Linux core tests and 8 Python checks passed. Apple native compilation/UI/archive qualification is pending. Device writes and Respring require physical testing with a matching signing profile. Do not publish private device details or conversation transcripts.

The 0.2 reference below is historical qualification, not qualification of changed 0.3 code.

# Development status

## Implemented

- Universal SwiftUI project, five navigation areas, window-size layout policy and shared transaction actor.
- Typed plist import/export, nested editing/search, drafts, differences, verified backups and recovery.
- Dynamic Island field inspection, local baseline restoration and appearance observations across activity types.
- UTF-8 editing with file-version backups, ZIP/tendies inspection, previews and operation-log export.
- Persistent English/Simplified Chinese/Follow System selection with shared localization state.
- GitHub Actions analysis, core/UI tests, device archive, IPA validation and guarded draft release.

Source `38a362f817be8b13a4c96d7d9380f9320c428c7d` passed [run 43593518290](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290): 63 core tests, 8 Python checks, four UI scenarios per simulator, analysis and unsigned build 10. Full evidence is in TEST_REPORT.md. The guarded release workflow succeeded; v0.2.0-dev is retained as a development draft with the unsigned IPA. This is a local-tool development release; system integration remains incomplete.

## Remaining work

1. Keep artifact qualification bound to the exact successful source above. Document-only updates do not certify changed app code.
2. Add UI coverage for import, text editing, archive export and backup restoration.
3. Validate continuous Stage Manager resizing, external display, VoiceOver and simultaneous multiwindow language changes.
4. Add user-selected directory browsing, retained text drafts, scroll/focus persistence and backup retention.
5. Implement bounded wallpaper-provider parsing, image/audio processing and share-extension handoff.
6. Review native pairing independently. System writes require a supported access mechanism, device identity, trusted originals and verified recovery; pairing alone is insufficient.
7. Continue iPad Dynamic Island shape/layout research across idle and all activity states. No verified system geometry control is available.

## Checks

`swift test`; `python3 -m unittest discover -s Tests -p 'test_*.py'`; `python3 scripts/check_repository.py`. Project and localization generation must remain reproducible. Audit scripts use the separately pinned upstream repositories.
