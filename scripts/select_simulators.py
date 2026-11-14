#!/usr/bin/env python3
import json, sys
runtimes=json.load(open(sys.argv[1]))['devices']
for kind,key in [('iPhone','IPHONE_SIM'),('iPad','IPAD_SIM')]:
    matches=[(runtime,d) for runtime,devices in runtimes.items() if 'iOS' in runtime for d in devices if d.get('isAvailable') and kind in d['name']]
    if not matches: raise SystemExit(f'No available {kind} simulator; do not silently skip UI tests')
    runtime,device=sorted(matches,key=lambda pair:pair[0])[-1]
    print(key+'='+device['udid'])
