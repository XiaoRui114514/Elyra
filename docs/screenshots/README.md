# Simulator UI evidence — 0.4.1

Original attachments from [run 43680976089](https://github.com/XiaoRui114514/Elyra/actions/runs/43680976089), source `94942ddebc8ae60474be8bb10620e8f503420ebb`. Nine tests passed on each 26.2 simulator, without retry. These are app-interface captures, not physical system-effect evidence.

| Page | iPhone | iPad |
| --- | --- | --- |
| Intelligence recipe | [Screenshot](v0.4.1/iphone-intelligence.png) | [Screenshot](v0.4.1/ipad-intelligence.png) |
| Model-name editor | [Screenshot](v0.4.1/iphone-model-name.png) | [Screenshot](v0.4.1/ipad-model-name.png) |
| System | [Screenshot](v0.4.1/iphone-system.png) | [Screenshot](v0.4.1/ipad-system.png) |
| Maximum Chinese text | [Screenshot](v0.4.1/iphone-large-text.png) | [Screenshot](v0.4.1/ipad-large-text.png) |

Original names, source IDs and hashes: [iPhone manifest](v0.4.1/iphone-manifest.json), [iPad manifest](v0.4.1/ipad-manifest.json). Simulator write controls are intentionally disabled. The synthetic editor text contains no individual device details. Long native English navigation titles can ellipsize; their full entry label and accessibility text remain available.

---

# Simulator UI evidence — 0.4

Original PNG attachments from [run 43676397713](https://github.com/XiaoRui114514/Elyra/actions/runs/43676397713), code source `b1e85e16a8c3195919fc4bc0ec5d33d4689a21f7`. Runtime 26.2 (23C54). iPhone evidence is from attempt 1; iPad evidence is from attempt 2 after a Simulator startup timeout. These show Elyra's interface, not physical-device system changes.

| Page | iPhone | iPad |
| --- | --- | --- |
| System overview | [Screenshot](v0.4/iphone-system.png) | [Screenshot](v0.4/ipad-system.png) |
| Repeated feature enter/back | [Screenshot](v0.4/iphone-round-trips.png) | [Screenshot](v0.4/ipad-round-trips.png) |
| Saved configuration plans | [Screenshot](v0.4/iphone-plans.png) | [Screenshot](v0.4/ipad-plans.png) |
| Window/display diagnostics | [Screenshot](v0.4/iphone-display.png) | [Screenshot](v0.4/ipad-display.png) |
| Direct account cards | [Screenshot](v0.4/iphone-about.png) | [Screenshot](v0.4/ipad-about.png) |
| Maximum Chinese accessibility text | [Screenshot](v0.4/iphone-large-text.png) | [Screenshot](v0.4/ipad-large-text.png) |
| Language settings | [Screenshot](v0.4/iphone-language.png) | [Screenshot](v0.4/ipad-language.png) |

Original names, test identities and SHA-256 values: [iPhone manifest](v0.4/iphone-manifest.json), [iPad manifest](v0.4/ipad-manifest.json). Publisher artwork provenance remains in [brand-assets.json](../audit/brand-assets.json). Continuous Stage Manager resize, physical window/display acceptance and system Dynamic Island geometry remain unverified.

---

# Simulator UI evidence — 0.3

Original PNG attachments from successful [run 43617128024](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024), source `b0f2232d3ff989cfae673dce94241dc4eebd563e`. Runtime 26.2 (23C54). These are app-interface captures on simulators, not physical-device system-change evidence. Original attachment names and SHA-256 values: [0.3 manifest](v0.3/manifest.json).

| Page | iPhone | iPad |
| --- | --- | --- |
| Direct About account cards | [Screenshot](v0.3/iphone-about.png) | [Screenshot](v0.3/ipad-about.png) |
| System overview | [Screenshot](v0.3/iphone-system.png) | [Screenshot](v0.3/ipad-system.png) |
| Home device actions | [Screenshot](v0.3/iphone-home.png) | [Screenshot](v0.3/ipad-home.png) |
| Maximum Chinese accessibility text | [Screenshot](v0.3/iphone-large-text.png) | [Screenshot](v0.3/ipad-large-text.png) |
| Language settings | [Screenshot](v0.3/iphone-language.png) | [Screenshot](v0.3/ipad-language.png) |

The account icons are original publisher artwork identified in [asset provenance](../audit/brand-assets.json). Simulator controls do not invoke the native system access or Respring modules. Continuous Stage Manager resizing and external-display acceptance remain unverified.

---

# Historical 0.2 evidence

Original PNG attachments from successful [run 43593518290](https://github.com/XiaoRui114514/Elyra/actions/runs/43593518290), source `38a362f817be8b13a4c96d7d9380f9320c428c7d`. Runtime 26.2 (23C54). Original attachment names and SHA-256 values are in [manifest.json](manifest.json).

- [iPhone language settings](iphone-language.png)
- [iPhone maximum accessibility text](iphone-dynamic-type.png)
- [iPad language settings and sidebar](ipad-language.png)
- [iPad Dynamic Island configuration page](ipad-dynamic-island.png)

These captures show Elyra's interface on iPhone SE 3 and iPad mini A17 Pro simulators. They do not show system Dynamic Island changes or physical-device installation, and do not validate continuous Stage Manager resizing. Full screenshot sets and xcresult summaries are in the corresponding run artifacts.
