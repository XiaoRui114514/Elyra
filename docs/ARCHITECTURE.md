# Architecture

Elyra is a universal SwiftUI application with a platform-independent Swift core. Minimum deployment target: iOS/iPadOS 17. Apple compilation/analyze and simulator qualification are tracked per source SHA in TEST_REPORT. This is not OS 27 device verification.

- `App/`: one `AppEnvironment` and one `Workspace` actor per application, shared across WindowGroup scenes. A corrupt library fails visibly rather than creating a replacement library.
- `Core/PlistValue`: recursive Sendable value tree; eight Foundation plist types, strict numeric/Boolean distinction, finite numbers/dates, input bounds and nesting limit. Paths are arrays of components, not delimiter-split user keys. Differences use collision-resistant length-prefixed IDs.
- `Core/Capability`: attributed GPL catalog from GestaltX, deduplicated as one engine. Presets stage changes in one shared editor, with separate local and live-device commit paths. On-device Siri refuses a generic replacement. No fixed-offset binary presets.
- `Core/Workspace`: managed copy import, original imported baseline, pre-save backup, local optimistic revision validation, atomic file replacement, readback, commit journal, recovery and persistent history. Imports never gain device ownership merely by being in this library.
- `Core/Compatibility`: separates UI, local files, system reads, system writes, visual results. No OS major grants write access. Seven status labels are represented. Current system status requires conditions; UI and visual effects unverified, local files partial because core tests are not Apple picker/runtime tests.
- `Features/`: real document editor, changes confirmation, backup comparison/restore/export, asset library and recoverable Trash, capability reference pages, diagnostics/history, Dynamic Island Lab.
- `DesignSystem/`: native lists, semantic colors, content labels, warnings/status components. `WindowLayout` derives compact/medium/wide from actual available dimensions and accessibility size.
- `Resources/`: original app icon, English/Simplified Chinese strings, privacy manifest and unmodified upstream license texts.
- `Tests/`: portable correctness/integrity/concurrency tests. `UITests/`: navigation/rotation, accessibility, observation persistence and language switching executed through macOS Actions.

## Transaction boundary

Read current bytes → compare expected SHA-256 revision → validate typed edit and size → write and read-verify backup → persist backup metadata → write commit journal → atomic replacement → exact readback → persist operation index → remove journal. Failure tries exact-byte rollback and verifies it; failure of recovery remains explicit. Restart recovery accepts only the expected or desired digest; neither match fails closed. This covers managed document commits, not arbitrary system writes.

The Workspace actor serializes local operations within one process. It does not establish system permissions. Extreme import/asset/trash interruptions can orphan files; the journal does not cover all file operations. No disk-power-loss fsync certification is claimed.

## UI versus data

Each scene retains area, navigation, search and a scene-specific draft identity. Drafts store base revision and typed values; stale drafts cannot be saved without reload/reconciliation. Persisted data, favorites, history and backups are shared. A successful operation refreshes all windows through the shared observable environment. Scroll-position restoration is not implemented yet. Full tree materialization/search and hashing large assets require future profiling.

## System backend boundary

`DeviceBackend` opens only the fixed MobileGestalt cache path. It first tries direct permission; otherwise it uses the pinned upstream `worse_query`, `GXCacheDirectory` and `GXEntitlementsReader` modules on 26/27. A declared entitlement alone is insufficient: the signed App Group must have an accessible container, and actual descriptor reads/writes determine readiness. Simulator access is disabled. Sandbox tokens are released and never logged.

One shared `SystemConfigurationStore` actor owns live sessions and device backups. A random, device-only Keychain secret binds backups to this installation; its SHA-256 is stored, not the secret. A canonical generation hash preserves all fields except the explicitly editable capability/artwork values. Imported files cannot mint a live session or become device backups.

A system commit validates the allowlist and source session, opens the real file with a nonblocking advisory exclusive lock, checks device/inode and revision, saves/verifies pre-write bytes and index, persists a recovery journal, rechecks the file, writes/synchronizes the descriptor and compares exact readback. XML/binary format is preserved. Failures attempt verified byte-for-byte rollback. A pending journal blocks further writes and manual Respring; explicit recovery requires the same inode, installation binding and compatible cache generation. Protected hardware identity and binary CacheData changes are rejected. App Group cache-link cleanup is an upstream separate operation; abrupt process death during that operation is not covered by the system-write journal.

Respring is a manually confirmed experimental upstream WebKit action. It never runs automatically after a commit and never runs in simulator tests. A scene-local presentation prevents duplicate WebKit triggers across windows; a shared busy flag blocks device operations. No physical restart success is claimed.

## 0.2 additions

DynamicIslandEngine centralizes flag staging, actual local configuration inspection and targeted baseline recovery; the generic capability catalog routes DI through the same code. Observation records carry automatic simulator provenance and optional local revision, with versioned library migration. Text assets have raw-byte backups and a separate commit journal; rollback restores matching metadata as well as bytes. Offline archives use pinned ZIPFoundation plus independent bounded preflight and streamed validation, with no extraction into system directories. See ARCHIVE_FORMATS.md.

Language settings use one shared LocalizationStore. SwiftUI locale and dynamic resource lookups resolve the same selected language. Workspace schema 3 accepts libraries from versions 1 and 2; observation report schema 2 allows playback state to be absent for non-media activities.
