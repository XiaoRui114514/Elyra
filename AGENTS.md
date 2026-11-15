# Repository engineering rules

Read docs/TASKS.md, KNOWN_ISSUES.md, FEATURE_MATRIX.md and TEST_REPORT.md before changes.

- Share one Workspace actor across windows; retain revision checks, verified backups and recovery journals.
- Use actual window geometry. Preserve iPhone/iPad feature parity and scene navigation/drafts.
- Imported files are local copies, not authenticated factory originals. Never guess original values, cache offsets or geometry parameters.
- System integration is authorized for this device customization app using the pinned public upstream access modules. Restrict the writer to MobileGestalt capability fields, require signed access, direct device capture, confirmation, backups, revision checks and readback. Do not add management-policy edits, hardware identity spoofing or destructive resets. Respring is an explicit manual experimental action only, never automatic.
- Dynamic Island research covers overall iPad shape/corners across activities. In-app previews and simulator images are not system-effect evidence.
- Keep public documentation technical and impersonal. Do not include individual device details, conversation transcripts or session narratives. Use synthetic test fixtures and simulator-only screenshots.
- Preserve GPL/source/dependency notices. Use the pinned upstream audit evidence accurately.
- Core changes: swift test. Python changes: unittest discovery. Always run scripts/check_repository.py; regenerate project/resources only as needed.
- Apple compile/analyze/UI/archive run on macOS Actions. Bind release qualification to the exact successful code SHA. Unsigned artifacts are not installation-tested.
- Keep terminology and language resources consistent. Language switches must retain scene/draft state and synchronize all windows.

- Release numbering: increment only the patch component by default (0.4.1 → 0.4.2). VERSION is the source of truth; regenerate the project. Change major/minor only when explicitly requested.
- Authorized display preferences include the three source-confirmed model-name fields and RegionCode. Retain sales-region suffixes and device-specific Siri values in the combined intelligence recipe. Hardware identifiers, serial numbers and binary cache fields remain protected.
