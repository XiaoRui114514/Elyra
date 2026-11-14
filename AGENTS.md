# Repository engineering rules

Read docs/TASKS.md, KNOWN_ISSUES.md, FEATURE_MATRIX.md and TEST_REPORT.md before changes.

- Share one Workspace actor across windows; retain revision checks, verified backups and recovery journals.
- Use actual window geometry. Preserve iPhone/iPad feature parity and scene navigation/drafts.
- Imported files are local copies, not authenticated factory originals. Never guess original values, cache offsets or geometry parameters.
- No system backend exists. Do not add sandbox escapes, management-policy edits, hardware spoofing, destructive resets or resource-exhaustion respring.
- Dynamic Island research covers overall iPad shape/corners across activities. In-app previews and simulator images are not system-effect evidence.
- Keep public documentation technical and impersonal. Do not include individual device details, conversation transcripts or session narratives. Use synthetic test fixtures and simulator-only screenshots.
- Preserve GPL/source/dependency notices. Use the pinned upstream audit evidence accurately.
- Core changes: swift test. Python changes: unittest discovery. Always run scripts/check_repository.py; regenerate project/resources only as needed.
- Apple compile/analyze/UI/archive run on macOS Actions. Bind release qualification to the exact successful code SHA. Unsigned artifacts are not installation-tested.
- Keep terminology and language resources consistent. Language switches must retain scene/draft state and synchronize all windows.
