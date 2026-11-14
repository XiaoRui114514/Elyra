#!/usr/bin/env python3
"""Portable static checks. These do not substitute for Xcode compilation."""
import ast, json, plistlib, re, struct, xml.etree.ElementTree as ET
from pathlib import Path
r=Path(__file__).resolve().parents[1]
required=['README.md','README_ZH-CN.md','LICENSE','THIRD_PARTY_NOTICES.md','CHANGELOG.md','Package.swift',
'Elyra.xcodeproj/project.pbxproj','Elyra.xcodeproj/xcshareddata/xcschemes/Elyra.xcscheme',
'.github/workflows/build.yml','.github/workflows/release.yml']
required += ['docs/'+name+'.md' for name in ['ARCHITECTURE','FEATURE_MATRIX','COMPATIBILITY','RESPONSIVE_UI','DYNAMIC_ISLAND_RESEARCH','BUILDING','INSTALLATION','TEST_REPORT','KNOWN_ISSUES','SOURCE_AUDIT','TASKS']]
for name in required:
    if not (r/name).is_file(): raise SystemExit('Missing '+name)
for p in (r/'scripts').glob('*.py'): ast.parse(p.read_text(),filename=str(p))
for p in (r/'Elyra/Resources').rglob('*.json'): json.loads(p.read_text())
info=plistlib.loads((r/'Elyra/Resources/Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='$(PRODUCT_BUNDLE_IDENTIFIER)'
assert info['UIApplicationSceneManifest']['UIApplicationSupportsMultipleScenes']
assert not info['UIRequiresFullScreen']
privacy=plistlib.loads((r/'Elyra/Resources/PrivacyInfo.xcprivacy').read_bytes())
assert not privacy['NSPrivacyTracking']
project=(r/'Elyra.xcodeproj/project.pbxproj').read_text()
for p in (r/'Elyra').rglob('*.swift'):
    assert str(p.relative_to(r)) in project, 'Source missing from target: '+str(p)
for match in re.finditer(r'path = "([^"]+)"; sourceTree = SOURCE_ROOT;',project):
    assert (r/match.group(1)).exists(), 'Broken project reference: '+match.group(1)
scheme=ET.fromstring((r/'Elyra.xcodeproj/xcshareddata/xcschemes/Elyra.xcscheme').read_text())
assert scheme.find('TestAction/Testables/TestableReference') is not None
sets=[]
for lang in ['en','zh-Hans']:
    lines=(r/f'Elyra/Resources/{lang}.lproj/Localizable.strings').read_text().splitlines()
    entries={}
    for line in lines:
        m=re.fullmatch(r'("(?:[^"\\]|\\.)*") = ("(?:[^"\\]|\\.)*");',line)
        assert m, 'Invalid localization syntax: '+line
        key,value=map(json.loads,m.groups())
        assert key not in entries and value;entries[key]=value
    sets.append(set(entries))
assert sets[0]==sets[1]
icon=(r/'Elyra/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
assert icon[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',icon[16:24])==(1024,1024)
source='\n'.join(p.read_text() for p in (r/'Elyra').rglob('*.swift'))
assert 'worse_query(' not in source and 'grantAccess(' not in source
assert 'TARGETED_DEVICE_FAMILY = "1,2"' in project
assert len(json.loads((r/'docs/audit/feature-matrix.json').read_text()))>=94
print(f'Static repository checks passed; {len(sets[0])} matching localization keys. Apple build/runtime remain unverified.')
