#!/usr/bin/env python3
import json, sys
from pathlib import Path
runtimes=json.load(open(sys.argv[1]))['devices']
families=[sys.argv[2]] if len(sys.argv)>2 else ['iPhone','iPad']
for family in families:
    if family not in ['iPhone','iPad']: raise SystemExit('Unknown simulator family')
    matches=[(runtime,d) for runtime,devices in runtimes.items() if 'iOS' in runtime for d in devices if d.get('isAvailable') and family in d['name']]
    if not matches: raise SystemExit(f'No available {family} simulator; UI tests cannot be skipped')
    latest=max(runtime for runtime,_ in matches)
    matches=[pair for pair in matches if pair[0]==latest]
    preferred=[pair for pair in matches if ('mini' in pair[1]['name'].lower() if family=='iPad' else 'SE' in pair[1]['name'])]
    runtime,device=(preferred or matches)[-1]
    key='SIMULATOR_ID' if len(families)==1 else 'IPHONE_SIM' if family=='iPhone' else 'IPAD_SIM'
    print(key+'='+device['udid'])
    if len(families)==1:
        Path('build/selected-simulator.json').write_text(json.dumps({'family':family,'runtime':runtime,'name':device['name'],'udid':device['udid']},indent=2)+'\n')
