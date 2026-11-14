#!/usr/bin/env python3
import json, os, re, subprocess
repo=os.environ['GITHUB_REPOSITORY'];run=os.environ['RUN_ID'];tag=os.environ['RELEASE_TAG']
if not run.isdigit() or not re.fullmatch(r'v[0-9][0-9A-Za-z._-]*',tag): raise SystemExit('Invalid run ID or tag')
def api(path): return json.loads(subprocess.check_output(['gh','api',path]))
data=api(f'repos/{repo}/actions/runs/{run}')
if data['conclusion']!='success' or data['event'] not in ['push','workflow_dispatch'] or data['path']!='.github/workflows/build.yml' or data['head_repository']['full_name']!=repo or data['head_branch']!='main': raise SystemExit('Require a successful main build in this repository')
sha=subprocess.check_output(['git','ls-remote','origin',f'refs/tags/{tag}',f'refs/tags/{tag}^{{}}'],text=True).splitlines()
if not sha or sha[-1].split()[0]!=data['head_sha']: raise SystemExit('Tag does not resolve to the verified build commit')
with open(os.environ['GITHUB_ENV'],'a') as env: env.write('VERIFIED_SHA='+data['head_sha']+'\n')
