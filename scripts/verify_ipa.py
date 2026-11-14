#!/usr/bin/env python3
"""Check a device IPA, not just a ZIP renamed to .ipa. No installation claims."""
import argparse, hashlib, json, plistlib, re, struct, zipfile
from pathlib import Path, PurePosixPath

def check_macho(data):
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
                check_macho(data[offset:offset+size]); return
    raise ValueError('Executable is not an arm64 Mach-O device executable')

def verify(path):
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
        extensions=sorted({n.split('.appex/')[0]+'.appex' for n in names if '.appex/' in n})
        if extensions: raise ValueError('Unexpected extension: verify signing and entitlements before adding it')
    return {'path':str(path),'sha256':hashlib.sha256(Path(path).read_bytes()).hexdigest(),'bundleID':info['CFBundleIdentifier'],'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'minimumOS':info['MinimumOSVersion'],'sdk':info.get('DTSDKName'),'executableBytes':len(binary),'architecture':'arm64','signatureDirectoryPresent':signed,'signing':'unsigned; requires legitimate signing' if not signed else 'signature present; validity and provisioning require codesign/device verification','installationTested':False}
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('ipa');args=parser.parse_args()
    print(json.dumps(verify(args.ipa),indent=2))
