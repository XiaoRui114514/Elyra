#!/usr/bin/env python3
import json, re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
translations=json.loads((r/'scripts/localizations.json').read_text())
keys=set(translations)
for file in (r/'Elyra').rglob('*.swift'):
    source=file.read_text()
    for m in re.finditer(r'(?:Text|Button|Label|Section|L|localization\.text|Picker|Toggle|Menu|LabeledContent|StatusNotice|ContentUnavailableView|TextField|DisclosureGroup|navigationTitle|searchable|keyboardShortcut|accessibilityLabel|alert|confirmationDialog)\(\s*"([^"\\]*)"',source): keys.add(m.group(1))
for file in (r/'Elyra').rglob('*.swift'):
    keys.update(re.findall(r'\.invalid\("([^"\\]*)"', file.read_text()))
for file in (r/'Elyra').rglob('*.swift'):
    keys.update(re.findall(r'(?:title|detail|prompt):\s*"([^"\\]*)"', file.read_text()))
for row in json.loads((r/'docs/audit/presets.json').read_text()): keys.add(row['detail']);keys.add(row['title'])
for lang in ['en','zh-Hans']:
    lines=[json.dumps(k,ensure_ascii=False)+' = '+json.dumps(translations.get(k,k) if lang=='zh-Hans' else k,ensure_ascii=False)+';' for k in sorted(keys) if k]
    (r/f'Elyra/Resources/{lang}.lproj/Localizable.strings').write_text('\n'.join(lines)+'\n')
missing=sorted(keys-translations.keys())
(r/'docs/audit/localization-fallbacks.json').write_text(json.dumps(missing,indent=2,ensure_ascii=False)+'\n')
print(f'{len(keys)} localization keys; {len(missing)} Chinese entries fall back to English (documented)')
