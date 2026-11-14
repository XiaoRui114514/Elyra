# Archive and text tool support

ZIPFoundation 0.9.20 is pinned by commit `22787ffb59de99e5dc1fbfe80b19c97a904ad48d` (MIT). It is now an actual compiled dependency; notices are bundled. Elyra performs its own bounded central-directory preflight before enumeration, rejects unsupported/skipped entries, validates safe and case-normalized paths and file/directory collisions, disallows links/encryption, checks streamed CRC/size and limits expansion. No archive entry is written into a system directory.

Limits: classic single-disk ZIP, compressed input ≤64 MB, ≤2,000 entries, ≤32 MB per entry, ≤128 MB total uncompressed. ZIP64/encrypted/unsupported filename encoding are explicitly rejected. Entry previews/exports are limited to 8 MB; text preview ≤1 MB. Images use ImageIO thumbnail decoding capped at 1,800 pixels, rather than rendering arbitrary original dimensions.

`.tendies` is inspected as an archive. Recognizing filenames such as `Wallpaper.plist` and PosterKit descriptors does not validate a full wallpaper provider, regenerate identifiers or install into PosterBoard. Those later functions remain incomplete. Dialer ZIPs can be inspected as files but are not automatically applied or resized.

UTF-8 editor: managed library copies only, ≤1 MB and no NUL/binary data. No-op keeps exact bytes; edits preserve a UTF-8 BOM when present. Before each actual write, verified raw file backup is persisted, a revision check rejects stale windows, a journal is written, output is atomically replaced/read back and metadata is updated. Reopening resolves only expected or desired bytes; unknown data fails closed. Restoring a file backup also backs up current bytes first and rejects cross-file/tampered backups. Initial asset import and Trash moves do not yet share this commit journal.
