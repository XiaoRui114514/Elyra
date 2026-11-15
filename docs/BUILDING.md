# Build and artifact workflow

Repository is live at https://github.com/XiaoRui114514/Elyra . Real arm64 IPAs are generated and independently verified. You do not need Xcode on Windows. Latest tested code, workflow results and hashes: TEST_REPORT.md.

## GitHub Actions

`.github/workflows/build.yml` runs on pushes changing code, pull requests and manual dispatch. Standard macOS 15 runners select an installed stable Xcode and record its exact SDK/Swift version. Current observed toolchain: Xcode 26.3 / SDK 26.2. This is not a promise of an iOS 27 SDK.

Three mandatory jobs run independently:

1. Reproducible project/localization/resource checks, Python IPA negative tests, Swift core tests, Xcode static analysis, generic-device Release archive, real IPA validation and artifact upload.
2. iPhone simulator UI tests.
3. iPad simulator UI tests.

Each UI job selects an available runtime/model (preferring a narrow iPhone and an iPad mini representative), runs on the runner's native architecture, and uploads full logs, xcresult, screenshot attachments and a summary. The whole run must succeed before treating an artifact as UI-tested or passing the release guard. Missing simulators are errors. Documentation-only commits can retain the exact tested code SHA without forcing an unrelated rebuild; reports must identify that SHA explicitly.

Concurrency is grouped by branch/PR and source SHA, allowing a newer revision to proceed independently of an obsolete run. Evidence export/upload has explicit time limits and runs on success or failure, with canceled runs excluded. This prevents a canceled xcresult export from holding subsequent builds; all core, analysis, UI and archive checks remain mandatory.

Debug uses standard ONLY_ACTIVE_ARCH=YES, Release NO. This fixes the observed mismatch where the app compiled an extra simulator slice while SwiftPM built only the native ZIPFoundation slice. No feature/dependency was removed to make compilation succeed.

## macOS commands

```sh
python3 scripts/check_repository.py
swift test
xcodebuild -resolvePackageDependencies -project Elyra.xcodeproj -scheme Elyra
xcodebuild build -project Elyra.xcodeproj -scheme Elyra \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>,arch=arm64' CODE_SIGNING_ALLOWED=NO
scripts/build_ipa.sh "$PWD/build"
```

`python3 scripts/generate_project.py` regenerates the committed Xcode app/UI-test project and scheme without a third-party generator. `python3 scripts/generate_localizations.py` maintains bilingual resources. ZIPFoundation is pinned to revision `22787ffb59de99e5dc1fbfe80b19c97a904ad48d` (0.9.20), both in SwiftPM and Xcode. Swift core can run on Linux with Swift 6 and zlib; Apple builds use Compression and include the package privacy resource.

## Real IPA packaging

`build_ipa.sh` archives for `generic/platform=iOS`, checks the actual application/executable, copies the entire app into `Payload/Elyra.app`, packages it and runs `verify_ipa.py`. It checks archive paths/duplicates, identifier, device families, iPhoneOS platform, executable permissions, arm64 Mach-O load commands/entry/text, notices/privacy and unreviewed extensions. An empty ZIP or simulator bundle is rejected. SHA-256 and a signing/installation-status JSON report are generated.

Outputs: `Elyra-unsigned.ipa`, `Elyra-resignable.ipa`, `SHA256SUMS`, both IPA reports, `Elyra.entitlements`, extracted `embedded-entitlements.plist`, `signature-metadata.txt`, archive and logs. The archive is unsigned. A separate staged copy receives an ad-hoc signature embedding the App Group template, verified by macOS codesign and the portable Mach-O parser. That template lets capable re-signers discover requested groups; it is not a certificate, provisioning profile or permission grant. The package artifact is named `Elyra-package-<source SHA>`. The app includes Objective-C native access modules, a bridging header, manual WebKit Respring and an App Groups signing template. It has no extension or Rust console. The entitlement sidecar is an input for legitimate provisioning/re-signing, not proof of granted permissions. ZIPFoundation is statically linked with its resource bundle/manifest. If adding dynamic frameworks/extensions, update project, verifier, signing and notices together.

CI archive build numbers use GITHUB_RUN_NUMBER (or explicit ELYRA_BUILD_NUMBER locally), and the JSON report records app version, build, minimum OS and SDK. The artifact ZIP contains an actual IPA plus evidence. Do not rename the artifact wrapper ZIP to IPA. Unsigned output needs a legitimate certificate/profile/signing tool. Bundle ID is currently `org.elyra.Elyra`; re-signing must provision or consistently replace it. The re-signable copy is ad-hoc signed without a team/provisioning profile. Both outputs require legitimate signing before installation; no physical installation is established by archive success.

## Release and failure handling

`release.yml` manual dispatch requires an existing `v*` tag and a successful matching main workflow run. It verifies origin, workflow, event and exact tag SHA, downloads the matching package, checks both IPA hashes/structures and creates a draft prerelease. It does not publish a stable/system-validated application. Keep signing and physical acceptance status in release notes.

For failures, inspect complete logs and xcresult/screenshot attachments, fix the true source/config issue, push, and inspect the new run. Use GitHub connector log/artifact tools if `gh` cannot follow storage redirects. A prior green build never proves a later feature change green.
