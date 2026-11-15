# Contributing to Elyra

[English guide](README.md) · [简体中文](README_ZH-CN.md)

Start with [AGENTS.md](AGENTS.md), [current tasks](docs/TASKS.md), [known issues](docs/KNOWN_ISSUES.md), the [feature matrix](docs/FEATURE_MATRIX.md) and [test report](docs/TEST_REPORT.md). A planned feature, simulator result and physical-device result are separate kinds of evidence.

## Report a problem

Include the app version/build, relevant source SHA, installation/signing method, OS version, window/orientation and minimal reproduction steps. Distinguish local-file editing from live-device access. Redact identifiers, account information and personal file contents. Do not upload a real MobileGestalt cache or device backup; use a synthetic fixture that isolates the issue.

Describe actual behavior and expected behavior. An in-app preview is not evidence of a SpringBoard appearance change. For a failed operation, retain the recovery state locally and describe the error rather than repeatedly attempting writes.

## Make a change

Keep one Workspace actor, revision checks, verified backups, recovery journals and exact readback. Imported files do not establish factory values or device trust. Preserve the restricted writer and protected fields; do not add guessed offsets, identity spoofing, management-policy edits or destructive resets.

Use synthetic test fixtures. Keep both language resources aligned and preserve scene navigation/drafts across language changes. Public documentation should be technical and impersonal. Do not change release numbering for a documentation-only edit; normal app releases increment the patch version through `VERSION` and regenerate the project.

## Validate

```sh
swift test
python3 -m unittest discover -s Tests -p 'test_*.py'
python3 scripts/check_repository.py
```

Regenerate the Xcode project/localizations when their inputs change and confirm the output is reproducible. Native compilation, analysis, simulator UI and IPA verification run on macOS through the [build workflow](.github/workflows/build.yml). Bind any release qualification to the exact successful code SHA. Documentation changes do not qualify new app code.

Record the checks actually run and anything unavailable. Unsigned/re-signable packages still require legitimate signing; neither packaging nor simulator success proves installation, real-device restoration, service activation or system appearance. Physical acceptance remains a separate step.

Retain [GPL-3.0-only terms](LICENSE), source attribution and [dependency notices](THIRD_PARTY_NOTICES.md).
