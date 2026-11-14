#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:-$PWD/build}"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
xcodebuild -version
xcodebuild -resolvePackageDependencies -project Elyra.xcodeproj -scheme Elyra
xcodebuild archive -project Elyra.xcodeproj -scheme Elyra -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$output/Elyra.xcarchive" \
  CURRENT_PROJECT_VERSION="${ELYRA_BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-2}}" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO | tee "$output/archive.log"
app="$output/Elyra.xcarchive/Products/Applications/Elyra.app"
test -d "$app"
test -x "$app/Elyra"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/Payload"
ditto "$app" "$stage/Payload/Elyra.app"
rm -f "$output/Elyra-unsigned.ipa" "$output/Elyra-resignable.ipa"
(cd "$stage" && /usr/bin/zip -qry "$output/Elyra-unsigned.ipa" Payload)
cp Elyra/Resources/Elyra.entitlements "$output/Elyra.entitlements"
python3 scripts/verify_ipa.py "$output/Elyra-unsigned.ipa" --expect-signing unsigned > "$output/ipa-report.json"
# Preserve App Group discovery for re-signers, as the pinned upstream build does.
# This ad-hoc template is not a provisioned or directly installable signature.
staged_app="$stage/Payload/Elyra.app"
while IFS= read -r -d '' item; do
  codesign --force --sign - --timestamp=none "$item"
done < <(find "$staged_app" -depth \( -name '*.framework' -o -name '*.dylib' \) -print0)
codesign --force --sign - --timestamp=none --generate-entitlement-der --entitlements Elyra/Resources/Elyra.entitlements "$staged_app"
codesign --verify --strict "$staged_app"
codesign -d --entitlements - --xml "$staged_app" > "$output/embedded-entitlements.plist"
codesign -dvv "$staged_app" 2> "$output/signature-metadata.txt"
python3 - "$output" <<'VERIFY_SIGNING'
import pathlib, plistlib, sys
root=pathlib.Path(sys.argv[1])
actual=plistlib.loads((root/'embedded-entitlements.plist').read_bytes())
expected=plistlib.loads((root/'Elyra.entitlements').read_bytes())
assert actual == expected, 'Embedded entitlements differ from signing template'
assert not actual.get('com.apple.developer.team-identifier'), 'Unexpected developer identity'
metadata=(root/'signature-metadata.txt').read_text()
assert 'Signature=adhoc' in metadata and 'TeamIdentifier=not set' in metadata
VERIFY_SIGNING
(cd "$stage" && /usr/bin/zip -qry "$output/Elyra-resignable.ipa" Payload)
python3 scripts/verify_ipa.py "$output/Elyra-resignable.ipa" --expect-signing adhoc > "$output/resignable-ipa-report.json"
(cd "$output" && shasum -a 256 Elyra-resignable.ipa Elyra-unsigned.ipa > SHA256SUMS)
