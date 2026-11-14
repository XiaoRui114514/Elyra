# Architecture

Elyra is a universal SwiftUI application with a platform-independent Swift core. Minimum deployment target: iOS/iPadOS 17. Baseline Apple compilation/analyze and 26.2 simulator tests passed; latest 0.2 results are in TEST_REPORT. This is not OS 27 device verification.

- `App/`: one `AppEnvironment` and one `Workspace` actor per application, shared across WindowGroup scenes. A corrupt library fails visibly rather than creating a replacement library.
- `Core/PlistValue`: recursive Sendable value tree; eight Foundation plist types, strict numeric/Boolean distinction, finite numbers/dates, input bounds and nesting limit. Paths are arrays of components, not delimiter-split user keys. Differences use collision-resistant length-prefixed IDs.
- `Core/Capability`: attributed GPL catalog from GestaltX, deduplicated as one engine. Presets only stage local edits. On-device Siri refuses a generic replacement. No fixed-offset binary presets.
- `Core/Workspace`: managed copy import, original imported baseline, pre-save backup, local optimistic revision validation, atomic file replacement, readback, commit journal, recovery and persistent history. Imports never gain device ownership merely by being in this library.
- `Core/Compatibility`: separates UI, local files, system reads, system writes, visual results. No OS major grants write access. Seven status labels are represented. Current system status requires conditions; UI and visual effects unverified, local files partial because core tests are not Apple picker/runtime tests.
- `Features/`: real document editor, changes confirmation, backup comparison/restore/export, asset library and recoverable Trash, capability reference pages, diagnostics/history, Dynamic Island Lab.
- `DesignSystem/`: native lists, semantic colors, content labels, warnings/status components. `WindowLayout` derives compact/medium/wide from actual available dimensions and accessibility size.
- `Resources/`: original app icon, English/Simplified Chinese strings, privacy manifest and unmodified upstream license texts.
- `Tests/`: portable correctness/integrity/concurrency tests. `UITests/`: navigation/rotation, accessibility, observation persistence and language switching executed through macOS Actions.

## Transaction boundary

Read current bytes → compare expected SHA-256 revision → validate typed edit and size → write and read-verify backup → persist backup metadata → write commit journal → atomic replacement → exact readback → persist operation index → remove journal. Failure tries exact-byte rollback and verifies it; failure of recovery remains explicit. Restart recovery accepts only the expected or desired digest; neither match fails closed. This covers managed document commits, not arbitrary system writes.

The actor serializes one process's windows. It does not create a cross-process filesystem lock or an exploit entitlement. Extreme import/asset/trash interruptions can orphan files; the journal does not cover all file operations. No disk-power-loss fsync certification is claimed.

## UI versus data

Each scene retains area, navigation, search and a scene-specific draft identity. Drafts store base revision and typed values; stale drafts cannot be saved without reload/reconciliation. Persisted data, favorites, history and backups are shared. A successful operation refreshes all windows through the shared observable environment. Scroll-position restoration is not implemented yet. Full tree materialization/search and hashing large assets require future profiling.

## System backend boundary

`requireSystemWriter()` always throws in this build. There is no interface that pretends a successful sandbox write is an applied system change. A future legitimate backend must supply independent device identity, exact build evidence, authorized target access, trusted original capture, input/schema validation, inter-window transaction exclusion, readback and tested recovery. Ordinary app signing is insufficient.

## 0.2 additions

DynamicIslandEngine centralizes flag staging, actual local configuration inspection and targeted baseline recovery; the generic capability catalog routes DI through the same code. Observation records carry automatic simulator provenance and optional local revision, with versioned library migration. Text assets have raw-byte backups and a separate commit journal; rollback restores matching metadata as well as bytes. Offline archives use pinned ZIPFoundation plus independent bounded preflight and streamed validation, with no extraction into system directories. See ARCHIVE_FORMATS.md.

Language settings use one shared LocalizationStore. SwiftUI locale and dynamic resource lookups resolve the same selected language. Workspace schema 3 accepts libraries from versions 1 and 2; observation report schema 2 allows playback state to be absent for non-media activities.
