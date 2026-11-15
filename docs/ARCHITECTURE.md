# Architecture

Elyra is a universal SwiftUI application with a platform-independent Swift core. Minimum deployment target: iOS/iPadOS 17. Apple compilation/analyze and simulator qualification are tracked per source SHA in TEST_REPORT. This is not OS 27 device verification.

- `App/`: one `AppEnvironment` and one `Workspace` actor per application, shared across WindowGroup scenes. A corrupt library fails visibly rather than creating a replacement library.
- `Core/PlistValue`: recursive Sendable value tree; eight Foundation plist types, strict numeric/Boolean distinction, finite numbers/dates, input bounds and nesting limit. Paths are arrays of components, not delimiter-split user keys. Differences use collision-resistant length-prefixed IDs.
- `Core/Capability`: attributed GPL catalog from GestaltX, deduplicated as one engine. Presets stage changes in one shared editor, with separate local and live-device commit paths. On-device Siri refuses a generic replacement. No fixed-offset binary presets.
- `Core/Workspace`: managed copy import, original imported baseline, pre-save backup, local optimistic revision validation, atomic file replacement, readback, commit journal, recovery and persistent history. Imports never gain device ownership merely by being in this library.
- `Core/Compatibility`: separates UI, local files, system reads, system writes, visual results. No OS major grants write access. Seven status labels are represented. Current system status is based on an actual connection/probe; visual effects remain independently unverified.
- `Features/`: real document editor, changes confirmation, backup comparison/restore/export, asset library and recoverable Trash, responsive capability tiles with direct Modify actions, saved configuration plans, current-window/display diagnostics, history and Dynamic Island Lab.
- `DesignSystem/`: native lists, semantic colors, content labels, warnings/status components. `WindowLayout` derives compact/medium/wide from actual available dimensions and accessibility size.
- `Resources/`: original app icon, English/Simplified Chinese strings, privacy manifest and unmodified upstream license texts.
- `Tests/`: portable correctness/integrity/concurrency tests. `UITests/`: navigation/rotation, accessibility, observation persistence and language switching executed through macOS Actions.

## Transaction boundary

Read current bytes → compare expected SHA-256 revision → validate typed edit and size → write and read-verify backup → persist backup metadata → write commit journal → atomic replacement → exact readback → persist operation index → remove journal. Failure tries exact-byte rollback and verifies it; failure of recovery remains explicit. Restart recovery accepts only the expected or desired digest; neither match fails closed. This covers managed document commits, not arbitrary system writes.

The Workspace actor serializes local operations within one process. It does not establish system permissions. Extreme import/asset/trash interruptions can orphan files; the journal does not cover all file operations. No disk-power-loss fsync certification is claimed.

## UI versus data

Each scene retains area, navigation, search and a scene-specific draft identity. Drafts store base revision and typed values; stale drafts cannot be saved without reload/reconciliation. Persisted data, favorites, history and backups are shared. A successful operation refreshes all windows through the shared observable environment. Scroll-position restoration is not implemented yet. Field indexes are cached per document revision and share a bounded search budget; unchanged live captures reuse the managed working document. Large-file performance still requires profiling.

## System backend boundary

`DeviceBackend` opens only the fixed MobileGestalt cache path. It first tries direct permission; otherwise it uses the pinned upstream `worse_query`, `GXCacheDirectory` and `GXEntitlementsReader` modules on 26/27. A declared entitlement alone is insufficient: the signed App Group must have an accessible container, and actual descriptor reads/writes determine readiness. Simulator access is disabled. Sandbox tokens are released and never logged.

One shared `SystemConfigurationStore` actor owns live sessions and device backups. A random, device-only Keychain secret binds backups to this installation; its SHA-256 is stored, not the secret. A canonical generation hash preserves all fields except the explicitly editable capability/artwork values. Imported files cannot mint a live session or become device backups.

A system commit validates the allowlist and source session, opens the real file with a nonblocking advisory exclusive lock, checks device/inode and revision, saves/verifies pre-write bytes and index, persists a recovery journal, rechecks the file, writes/synchronizes the descriptor and compares exact readback. XML/binary format is preserved. Failures attempt verified byte-for-byte rollback. A pending journal blocks further writes and manual Respring; explicit recovery requires the same inode, installation binding and compatible cache generation. Protected hardware identity and binary CacheData changes are rejected. App Group cache-link cleanup is an upstream separate operation; abrupt process death during that operation is not covered by the system-write journal.

Respring is a manually confirmed experimental upstream WebKit action. It never runs automatically after a commit and never runs in simulator tests. A scene-local presentation prevents duplicate WebKit triggers across windows; a shared busy flag blocks device operations. No physical restart success is claimed.

## 0.2 additions

DynamicIslandEngine centralizes flag staging, actual local configuration inspection and targeted baseline recovery; the generic capability catalog routes DI through the same code. Observation records carry automatic simulator provenance and optional local revision, with versioned library migration. Text assets have raw-byte backups and a separate commit journal; rollback restores matching metadata as well as bytes. Offline archives use pinned ZIPFoundation plus independent bounded preflight and streamed validation, with no extraction into system directories. See ARCHIVE_FORMATS.md.

Language settings use one shared LocalizationStore. SwiftUI locale and dynamic resource lookups resolve the same selected language. Workspace schema 3 accepts libraries from versions 1 and 2; observation report schema 2 allows playback state to be absent for non-media activities.

## 0.4 configuration and navigation

Each scene stores a separate navigation path for each primary area. Compact tabs and split-view detail use the same path binding and destinations. System overview, categories and feature detail share adaptive tiles/panels; Dynamic Island belongs to Display. Access is automatically probed once when entering System. Connection status and direct Modify controls reflect a real capture and writer result; a planning/input error does not falsely revoke a valid connection.

ConfigurationPlan is a bounded versioned JSON document containing known capability IDs and apply/restore intent. It contains no original cache values or device identity. Imports receive a fresh ID; actor-serialized writes and optimistic baseline comparison reject conflicting edits across windows. All plan steps are resolved against one live snapshot, with explicit overlapping-field conflict detection and one reviewed commit/backup transaction. Binary Boolean presets preserve existing Boolean plist types. Dynamic Island restoration restores the captured flag and subtype together while preserving unrelated Artwork values.

Device backup inspection/export verifies installation binding, generation and bytes without opening the system target. Restoring to the device remains a separate confirmed transaction. Recovery refuses an unexpected valid cache instead of overwriting external edits; partial corrupt bytes are retained before explicit verified restoration. Expired editor sessions reconnect with a three-way draft merge and reject overlapping changes.

Window & display uses the actual UIWindowScene.screen and the current window's bounds/safe area. CADisplayLink sampling is optional and stops when leaving the view or becoming inactive. The reported callback rate is application scheduling, not panel refresh or PWM. EDR headroom is not measured peak brightness.
