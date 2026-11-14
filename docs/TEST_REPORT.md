# Test report

The release candidate is being validated by GitHub Actions. Only a complete successful build qualifies its exact source and unsigned IPA; partial job success is insufficient.

| Check | Current result |
| --- | --- |
| Linux core | 63 passed, Swift 6.0.3 |
| Python IPA negative tests | 8 passed |
| Localization resources | 419 matching English/Simplified Chinese keys, no unclassified fallback |
| Project/resources/workflow checks | Passed locally |
| Apple analysis/archive/UI | Final qualification pending |
| Signing | Unsigned build pipeline; no certificates supplied |
| Physical installation/system effects | Not tested |

The core suite covers typed plist values, baseline integrity, transaction conflicts/recovery, Dynamic Island field preservation, observation/schema migration, text-file versions, bounded ZIP validation, device-build parsing and language resolution. Four UI scenarios per simulator cover navigation/rotation, Chinese accessibility text, observation persistence and actual language switching/persistence.

Window-policy tests sweep widths 320–1600. They do not replace continuous Stage Manager resize, external-display or physical-device testing. Simulator rendering does not establish system Dynamic Island modification.
