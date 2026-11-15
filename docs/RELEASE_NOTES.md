Elyra 0.4.0 development release — build 26

System now uses adaptive tiles throughout the overview, categories and feature details. Each feature has a direct Modify action and actual access status; entering System automatically checks the device connection. Dynamic Island is part of Display. Primary areas retain independent navigation paths. Introductory text and the language footer have been reduced.

Adds reusable configuration plans with import/export and a combined change preview; verified offline device backup inspection/export; and current-window/display diagnostics with optional application callback measurement. Restoring Dynamic Island now includes its recorded subtype, Boolean presets preserve their type, recovery protects unexpected external edits, and reconnecting an editor can retain a nonconflicting draft.

Two arm64 IPA packages are included. Elyra-resignable.ipa embeds an ad-hoc App Group template so capable signing tools can discover it; Elyra-unsigned.ipa has no signature. Both require legitimate re-signing/provisioning and are not installation-tested. Actual system access still depends on the final signature, available container and file permission probe.

Qualification and checksums: [test report](https://github.com/XiaoRui114514/Elyra/blob/main/docs/TEST_REPORT.md). Physical system effects, iOS/iPadOS 27 runtime acceptance and a system Dynamic Island geometry repair are not established. See [feature matrix](https://github.com/XiaoRui114514/Elyra/blob/main/docs/FEATURE_MATRIX.md) for remaining migration work.

Qualified code: `b1e85e16a8c3195919fc4bc0ec5d33d4689a21f7`. [Run 43676397713](https://github.com/XiaoRui114514/Elyra/actions/runs/43676397713) passed 93 core tests, 14 Python checks, Xcode analysis/archive and eight UI scenarios per simulator. The iPad task passed on retry after a Simulator launch-progress timeout; app code was unchanged. Xcode 26.3, SDK/runtime 26.2.

Re-signable SHA-256: `c17151636c33c1fe931c319ec39440236067555deaa303cf36da6af5a57a2234`
Unsigned SHA-256: `cd9aa85f2776f636cb01fd25a20c469d676ec159f9344d15ca863f6b72f086f4`
