#!/usr/bin/env python3
"""Reproducible source inventory, pinned catalog extraction and audit evidence."""
import hashlib, json, re, subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
base = root.parent / 'upstream'
manifest = {}
for repo in ['Erosion', 'GestaltX']:
    source = base / repo
    sha = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    files = []
    for name in subprocess.check_output(['git', '-C', str(source), 'ls-files'], text=True).splitlines():
        path = source / name
        if not path.is_file(): continue
        data = path.read_bytes()
        entry = {'path': name, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
        if path.suffix in ['.swift', '.m', '.h', '.rs', '.sh', '.yml', '.toml']:
            text = data.decode('utf-8', errors='replace')
            entry['lines'] = len(text.splitlines())
            entry['declarations'] = re.findall(r'^\s*(?:(?:public|private|static|final|mutating|override|class|nonisolated)\s+)*(?:struct|enum|class|actor|func|fn|protocol)\s+(\w+)', text, re.M)
            entry['signals'] = sorted(set(re.findall(r'worse_query|grantAccess|CacheData|CacheExtra|ArtworkDeviceSubType|AppGroup|Keychain|SHA256|HMAC|symlink|respring|supervised|MDM', text, re.I)))
        files.append(entry)
    manifest[repo] = {'sha': sha, 'files': files}
(root / 'docs/audit/source-inventory.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False)+'\n')
source = (base / 'GestaltX/GestaltX/Capabilities.swift').read_text()
rows = []
for line in source.splitlines():
    m = re.search(r'\.init\(id: "(.*?)", category: \.(\w+), title: "(.*?)", detail: "(.*?)", keys: \[(.*?)\]', line)
    if not m: continue
    id, cat, title, detail, keys = m.groups()
    keylist = re.findall(r'"([^"]+)"', keys)
    if 'GestaltKeys.siriMode' in keys: keylist = ['bzLk5OMluFVLH43uOx3LYg'] # replaced below from actual declaration
    if id == 'siriAIMode':
        doc = (base / 'GestaltX/GestaltX/GestaltDocument.swift').read_text()
        keylist = [re.search(r'static let siriMode = "(.*?)"', doc).group(1)]
    value = 0 if id == 'parallax' else 3 if id == 'aodFlipbookCount' else 2 if id == 'siriAIMode' else 1
    rows.append(dict(id=id, category=cat, title=title, detail=detail, keys=keylist, value=value, caution='caution: true' in line))
(root / 'docs/audit/presets.json').write_text(json.dumps(rows, indent=2)+'\n')
def q(v): return json.dumps(v, ensure_ascii=False)
out = '''// SPDX-License-Identifier: GPL-3.0-only
// Key catalog adapted from GestaltX Capabilities.swift.
// Copyright (C) 2026 huamidev. Elyra adaptation (C) 2026 Elyra contributors.
import Foundation
public struct Capability: Identifiable, Sendable {
    public let id: String
    public let category: String
    public let title: String
    public let detail: String
    public let keys: [String]
    public let value: Int64
    public let caution: Bool
    public func stage(in document: inout PlistValue) throws {
        if id == "dynamicIsland" { document = try DynamicIslandEngine.enablingFlag(in: document); return }
        guard case .dictionary = document.value(at: ["CacheExtra"]) else { throw ElyraError.invalid("This document has no CacheExtra dictionary.") }
        guard id != "siriOnDevice" else { throw ElyraError.invalid("On-Device Siri has a device-specific type. Restore a recorded original instead of guessing.") }
        for key in keys {
            let target: PlistValue = id == "ipadApps" ? .array([.integer(1), .integer(2)]) : .integer(value)
            try document.set(target, at: ["CacheExtra", key])
        }
    }
    public static let all: [Self] = [
'''
for r in rows:
    out += '        .init(id: %s, category: %s, title: %s, detail: %s, keys: [%s], value: %d, caution: %s),\n' % (q(r['id']),q(r['category']),q(r['title']),q(r['detail']),', '.join(map(q,r['keys'])),r['value'],str(r['caution']).lower())
out += '    ]\n}\n'
(root / 'Elyra/Core/Capability.swift').write_text(out)
print({name: {'sha': v['sha'], 'files': len(v['files'])} for name,v in manifest.items()})
