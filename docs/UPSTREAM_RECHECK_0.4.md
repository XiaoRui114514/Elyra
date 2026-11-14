# Access and interface recheck

Re-fetched both repositories on 2026-11-14. Erosion HEAD remains `12c0a2d00c444c9b09112608b47d4d6c10e0df14`. GestaltX HEAD is now `72bf625befdb5e9e16d52c663e123f9fbc8ec7bf`; compared with pinned `d1d5473734440e8f2e797494ac373427c02fd674`, only README files changed. Native access code is unchanged.

## Confirmed differences

- GestaltX `.github/scripts/build-ipa.sh` embeds App Group entitlements in an ad-hoc signature, then checks the actual signature and group list. Erosion `ipabuild.sh` uses ldid to embed its entitlement declaration. Re-signers can discover requested groups from these signatures.
- Elyra 0.3 archived with signing disabled and supplied only an entitlement sidecar. Inspection of the actual published executable found no embedded App Groups. This can prevent automatic group registration by re-signers. It does not prove that every installation lacks access: a signer can supply valid groups independently.
- GestaltX automatically attempts a device read through `autoRead`; Elyra 0.3 required manual connection. Its generic unconnected badge did not distinguish an unperformed probe from a denied operation.
- Elyra 0.3's experimental feature badge was driven by `snapshot.writable`; it indicated a successful read/write access probe, not an unavailable OS. The device modification entry was buried below information blocks. The category screen still used the older list layout even though the dashboard had tiles.

## 0.4 changes

Use the same existing native query modes, actual signed/container access checks and fixed MobileGestalt target. Supply `Elyra-resignable.ipa` with an ad-hoc entitlement template, plus the separately labeled unsigned package. Inspect extracted XML entitlements and CodeDirectory flags, run codesign strict verification, compare the signed declaration with the source template and reject a bundled developer identity. Neither package is certificate/provisioning-signed or installation-tested.

Automatically probe when opening System or an individual capability. Show actual access state and concrete signing/container failures; never infer denial solely from an OS major. Provide a visible Modify action, a typed before/after confirmation and restoration from a verified initial device capture. Backups, revision checks and exact readback remain enforced. The large generic Dependencies & risk section is removed; no zero-risk claim is introduced.

Use one tile system throughout dashboard, category and feature screens; maintain independent navigation paths per area. Dynamic Island is a Display feature, with configuration/observation tools reachable within its detail page. Preserve actual feature entries; remove informational migration placeholders from the primary category interface and track incomplete modules in FEATURE_MATRIX.

## Version scope

GestaltX's version label is major 27; Erosion differentiates 26 query flags for some App Group paths. Different targets and modules have different support conditions. MobileGestalt access does not establish wallpaper, launch-artwork, sound, pairing or server-service availability. Elyra's unported system asset modules are an implementation gap, not evidence that the operating system is incompatible. Physical tests must record the actual read/write result and separately assess each feature's effect and restoration.
