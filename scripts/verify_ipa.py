#!/usr/bin/env python3
"""Check a device IPA, not just a ZIP renamed to .ipa. No installation claims."""
import argparse, hashlib, json, plistlib, re, struct, zipfile
from pathlib import Path, PurePosixPath

def check_macho(data, depth=0):
    if depth > 1: raise ValueError('Nested fat executable')
    if len(data) < 32: raise ValueError('Executable is truncated')
    magic,cpu,subtype,kind=struct.unpack_from('<IIII',data)
    if magic==0xfeedfacf:
        if cpu!=0x0100000c or kind!=2: raise ValueError('Expected arm64 MH_EXECUTE')
        ncmds,sizeofcmds=struct.unpack_from('<II',data,16)
        if not 0<ncmds<4096 or sizeofcmds>len(data)-32: raise ValueError('Invalid Mach-O load commands')
        pos=32;device=False;text=False;entry=False
        for _ in range(ncmds):
            if pos+8>32+sizeofcmds: raise ValueError('Truncated load command')
            cmd,size=struct.unpack_from('<II',data,pos)
            if size<8 or pos+size>32+sizeofcmds: raise ValueError('Invalid load command size')
            if cmd==0x32 and size>=24:
                platform=struct.unpack_from('<I',data,pos+8)[0]
                if platform!=2: raise ValueError('Executable was built for a non-iOS-device platform')
                device=True
            if cmd==0x25 and size>=16: device=True
            if cmd==0x19 and size>=72 and data[pos+8:pos+24].rstrip(b'\0')==b'__TEXT':
                fileoff,filesize=struct.unpack_from('<QQ',data,pos+40)
                if filesize==0 or fileoff+filesize>len(data): raise ValueError('Invalid __TEXT file range')
                text=True
            if cmd in [0x80000028,0x5]: entry=True
            pos+=size
        if pos!=32+sizeofcmds or not device or not text or not entry: raise ValueError('Missing device build, text segment, or entry point')
        return
    if data[:4] in [b'\xca\xfe\xba\xbe',b'\xca\xfe\xba\xbf']:
        is64=data[3]==0xbf
        count=struct.unpack_from('>I',data,4)[0]
        if not 0<count<=32: raise ValueError('Invalid fat header')
        for i in range(count):
            pos=8+i*(32 if is64 else 20)
            cpu=struct.unpack_from('>I',data,pos)[0]
            if is64: offset,size=struct.unpack_from('>QQ',data,pos+8)
            else: offset,size=struct.unpack_from('>II',data,pos+8)
            if cpu==0x0100000c:
                check_macho(data[offset:offset+size], depth+1); return
    raise ValueError('Executable is not an arm64 Mach-O device executable')

def signature_info(data, depth=0):
    """Read bounded XML entitlements/CD flags; codesign performs cryptographic verification on macOS."""
    if depth > 1 or len(data) < 32: raise ValueError('Invalid signature executable')
    if data[:4] in [b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf']:
        fat64=data[3]==0xbf; count=struct.unpack_from('>I', data, 4)[0]
        stride=32 if fat64 else 20
        if not 0<count<=32 or 8+count*stride>len(data): raise ValueError('Invalid fat signature table')
        for i in range(count):
            item=8+i*stride
            if struct.unpack_from('>I',data,item)[0]!=0x0100000c: continue
            offset,size=struct.unpack_from('>QQ' if fat64 else '>II',data,item+8)
            if offset>len(data) or size>len(data)-offset: raise ValueError('Invalid signature slice range')
            return signature_info(data[offset:offset+size],depth+1)
        raise ValueError('Missing arm64 signature slice')
    if struct.unpack_from('<I',data)[0]!=0xfeedfacf: raise ValueError('Unsupported signature Mach-O')
    count,total=struct.unpack_from('<II',data,16)
    if not 0<count<4096 or total>len(data)-32: raise ValueError('Invalid signature commands')
    cursor=32; end=32+total; blob=None
    for _ in range(count):
        if cursor+8>end: raise ValueError('Truncated signature command')
        command,length=struct.unpack_from('<II',data,cursor)
        if length<8 or length>end-cursor: raise ValueError('Invalid signature command size')
        if command==0x1d:
            if length<16 or blob is not None: raise ValueError('Invalid code signature command')
            offset,size=struct.unpack_from('<II',data,cursor+8)
            if offset>len(data) or size>len(data)-offset: raise ValueError('Code signature outside executable')
            blob=data[offset:offset+size]
        cursor+=length
    result={'present':blob is not None,'adhoc':False,'entitlements':None}
    if blob is None: return result
    if len(blob)<12: raise ValueError('Truncated signature superblob')
    magic,length,count=struct.unpack_from('>III',blob)
    if magic!=0xfade0cc0 or length>len(blob) or length<12 or count>(length-12)//8: raise ValueError('Invalid signature superblob')
    for i in range(count):
        slot,offset=struct.unpack_from('>II',blob,12+8*i)
        if offset<12+8*count or offset+8>length: raise ValueError('Invalid signature blob index')
        kind,size=struct.unpack_from('>II',blob,offset)
        if size<8 or size>length-offset: raise ValueError('Invalid signature blob length')
        if slot==0:
            if kind!=0xfade0c02 or size<16: raise ValueError('Invalid CodeDirectory')
            result['adhoc']=bool(struct.unpack_from('>I',blob,offset+12)[0]&2)
        if slot==5:
            if kind!=0xfade7171 or result['entitlements'] is not None: raise ValueError('Invalid XML entitlement slot')
            entitlements=plistlib.loads(blob[offset+8:offset+size])
            if not isinstance(entitlements,dict): raise ValueError('Entitlements must be a dictionary')
            result['entitlements']=entitlements
    return result


def verify(path, expected_signing=None):
    with zipfile.ZipFile(path) as archive:
        names=archive.namelist()
        if len(names)!=len(set(names)): raise ValueError('Duplicate archive entries')
        for name in names:
            p=PurePosixPath(name)
            if p.is_absolute() or '..' in p.parts or '\\' in name: raise ValueError('Unsafe archive path')
        apps={n.split('/')[1] for n in names if n.startswith('Payload/') and len(n.split('/'))>2 and n.split('/')[1].endswith('.app')}
        if apps!={'Elyra.app'}: raise ValueError('Expected only Payload/Elyra.app')
        base='Payload/Elyra.app/'
        info=plistlib.loads(archive.read(base+'Info.plist'))
        if info.get('CFBundleIdentifier')!='org.elyra.Elyra': raise ValueError('Unexpected bundle identifier')
        if info.get('CFBundlePackageType')!='APPL': raise ValueError('Not an application bundle')
        if set(info.get('UIDeviceFamily',[]))!={1,2}: raise ValueError('Not a universal iPhone/iPad app')
        if info.get('CFBundleSupportedPlatforms')!=['iPhoneOS']: raise ValueError('Not a device build')
        if not re.fullmatch(r'\d+(?:\.\d+){0,2}', str(info.get('CFBundleVersion',''))): raise ValueError('Missing or invalid build version')
        if not re.fullmatch(r'\d+(?:\.\d+){1,2}', str(info.get('CFBundleShortVersionString',''))): raise ValueError('Missing or invalid app version')
        if not re.fullmatch(r'\d+(?:\.\d+){1,2}', str(info.get('MinimumOSVersion',''))): raise ValueError('Missing deployment version')
        executable=info['CFBundleExecutable']
        if '/' in executable or executable in ['.','..']: raise ValueError('Invalid executable path')
        binary=archive.read(base+executable);check_macho(binary)
        mode=(archive.getinfo(base+executable).external_attr>>16)&0o777
        if not mode&0o111: raise ValueError('Executable permission missing')
        if not any(n.startswith(base+'Licenses/') for n in names): raise ValueError('Bundled licenses missing')
        if base+'PrivacyInfo.xcprivacy' not in names: raise ValueError('Privacy manifest missing')
        signed=any(n.startswith(base+'_CodeSignature/') for n in names)
        signature=signature_info(binary)
        entitlements=signature['entitlements'] or {}
        groups=entitlements.get('com.apple.security.application-groups',[])
        if not isinstance(groups,list) or not all(isinstance(x,str) and x for x in groups): raise ValueError('Invalid App Group entitlements')
        signing_mode='adhoc' if signed and signature['adhoc'] and groups else ('unsigned' if not signed and not entitlements else 'unverified')
        if expected_signing and signing_mode!=expected_signing: raise ValueError('Unexpected IPA signing mode')
        if expected_signing=='adhoc':
            if 'group.org.elyra.Elyra' not in groups: raise ValueError('App Group signing template missing')
            if entitlements.get('com.apple.developer.team-identifier') or entitlements.get('application-identifier'): raise ValueError('Developer identity must not be embedded in the re-signing template')
        extensions=sorted({n.split('.appex/')[0]+'.appex' for n in names if '.appex/' in n})
        if extensions: raise ValueError('Unexpected extension: verify signing and entitlements before adding it')
    return {'path':str(path),'sha256':hashlib.sha256(Path(path).read_bytes()).hexdigest(),'bundleID':info['CFBundleIdentifier'],'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'minimumOS':info['MinimumOSVersion'],'sdk':info.get('DTSDKName'),'executableBytes':len(binary),'architecture':'arm64','signatureDirectoryPresent':signed,'signingMode':signing_mode,'appGroups':groups,'signing':'ad-hoc entitlement template; requires legitimate re-signing' if signing_mode=='adhoc' else ('unsigned; requires legitimate signing' if signing_mode=='unsigned' else 'signature present; validity and provisioning require verification'),'requiresResigning':True,'installationTested':False}
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('ipa');parser.add_argument('--expect-signing',choices=['unsigned','adhoc']);args=parser.parse_args()
    print(json.dumps(verify(args.ipa,args.expect_signing),indent=2))
