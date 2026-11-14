Elyra 0.3.0 development release — build 18

Adds native MobileGestalt connection and restricted capability/artwork writes, actual signed-App-Group permission checks, device-bound backups, confirmed differences, exact readback, rollback and interrupted-write recovery. Imported files retain a separate local workflow. System effects depend on the exact build, hardware and effective access.

Home quick access and the special Dynamic Island placement are removed. Home adds manually confirmed experimental Respring. System has an adaptive category overview. About directly displays GitHub, Douyin and Xiaohongshu account cards with official publisher app icons and restrained brand colors; mandatory source notices remain on the separate license page. English, Simplified Chinese and Follow System are supported.

Validated source: `b0f2232d3ff989cfae673dce94241dc4eebd563e`. [CI run 43617128024](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024) passed 76 core tests, 8 IPA negative tests, Xcode analysis, device archive and five UI scenarios on each iPhone/iPad simulator. Xcode 26.3, SDK/runtime 26.2. The downloaded arm64 IPA was independently verified.

The IPA is unsigned. Signing must supply an App Group permitted by the provisioning profile when direct system access is unavailable; `Elyra.entitlements` is included as a template. Physical installation, native writes/restore, Respring and iOS/iPadOS 27 behavior remain untested. No system Dynamic Island radius/layout repair is established.

IPA SHA-256: `ee171a77bc4254da198e08653a16e7ddf062a566f50560211db307c9fc291487`. [Test report](https://github.com/XiaoRui114514/Elyra/blob/main/docs/TEST_REPORT.md).
