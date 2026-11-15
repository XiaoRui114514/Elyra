# 0.4.2 review and follow-up

Reviewed 2026-11-15 UTC. Erosion remote HEAD remains `fb16225faa120d258ca5b8856568cf504199598f`; GestaltX remote HEAD remains `72bf625befdb5e9e16d52c663e123f9fbc8ec7bf`. Native modules remain pinned to the audited versions; this patch does not change their access method.

## Implemented

The model-name entry previously sat outside the adaptive category grid. It now shares the sorted grid and tile dimensions with other capabilities. The editor has explicit native focus, Edit and keyboard Done controls, and per-scene draft storage. Successful apply/restore refreshes the field from the returned verified snapshot.

Root navigation previously used the GeometryReader height after keyboard avoidance. On a short landscape window, keyboard presentation could cross the 360-point compact-layout threshold and replace the navigation tree while a field was becoming first responder. The root now observes its actual scene UIWindow bounds minus window safe areas. Normal content keyboard avoidance remains enabled. The observer also serves window/display diagnostics and continues to report actual resize and safe-area changes. This addresses a concrete focus-loss path; physical-device confirmation remains pending.

References: [Apple FocusState](https://developer.apple.com/documentation/swiftui/focusstate), [Apple UIWindow](https://developer.apple.com/documentation/uikit/uiwindow), [Apple UIView.safeAreaInsets](https://developer.apple.com/documentation/uikit/uiview/safeareainsets). A [community reproduction](https://stackoverflow.com/questions/63529220/how-to-stop-geometryreader-changing-value-when-keyboard-opens) also documents GeometryReader shrinking when the keyboard opens. Its suggestion to use the main screen is unsuitable for Stage Manager/multiwindow; Elyra measures the current scene window instead.

The [pinned GestaltX RegionPreset catalog](https://github.com/huamidev/GestaltX/blob/d1d5473734440e8f2e797494ac373427c02fd674/GestaltX/Capabilities.swift) supplies seven raw codes: LL, ZA, J, CH, TA, B and C. They are now independently selectable under Intelligence. Country labels are omitted because the source alone does not independently validate each territory mapping. This operation changes only RegionCode, uses one reviewed transaction and can restore the exact captured original, including absence or an uncatalogued original value. Sales suffixes, model names and intelligence flags are retained. The existing backup generation field set does not expand.

## Next candidates

| Candidate | Evidence and implementation boundary | Status |
| --- | --- | --- |
| Selected-directory browser | Erosion FileBrowserView and latest container changes; Foundation security-scoped directory URLs can support ordinary authorized folders independently of system access | Next bounded file module; needs bookmark lifetime, enumeration limits and revocation tests |
| Local notification-audio conversion | GestaltX AppSoundCodec uses AVFoundation; local trim/convert/preview can be useful before a separately authorized container installation | Research candidate; validate duration, codec failures and original retention |
| Dialer image processing | Erosion KeypadManager defines image variants and size limits; local crop/resize/export can precede system installation | Research candidate; retain originals and enforce decode/output bounds |
| Keyboard and resize coverage across other editors | The navigation fix applies to all routes; model-name input now has dedicated keyboard regression | Expand focused workflows for text/plist editors without claiming continuous hardware resize coverage |
| Dynamic Island corner control | Separate aperture/screen-radius metrics are documented in DYNAMIC_ISLAND_RESEARCH; no verified scoped writer exists in this backend | Research only; no guessed cache key, full hardware-model impersonation or claimed radius repair |

The current patch selects a bounded missing upstream function and the keyboard/navigation improvements. Audio/container/pairing backends are not silently marked complete. App compilation and simulator UI qualification remain distinct from physical system writes and service activation.
