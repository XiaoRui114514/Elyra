# SPDX-License-Identifier: GPL-3.0-only
import importlib.util, plistlib, struct, tempfile, unittest, zipfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('verify',Path(__file__).resolve().parents[1]/'scripts/verify_ipa.py')
verify=importlib.util.module_from_spec(spec);spec.loader.exec_module(verify)

class IPANegativeTests(unittest.TestCase):
    def test_empty_zip_cannot_be_an_ipa(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'fixture.zip'
            with zipfile.ZipFile(path,'w'): pass
            with self.assertRaises(ValueError): verify.verify(path)
    def test_zip_path_traversal_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'fixture.zip'
            with zipfile.ZipFile(path,'w') as z: z.writestr('../bad','x')
            with self.assertRaises(ValueError): verify.verify(path)
    def test_text_is_not_an_executable(self):
        with self.assertRaises(ValueError): verify.check_macho(b'#!/bin/sh\necho not an app\n'+b'x'*40)
    def test_header_without_load_commands_is_rejected(self):
        header=struct.pack('<IIIIIIII',0xfeedfacf,0x0100000c,0,2,0,0,0,0)
        with self.assertRaises(ValueError): verify.check_macho(header)
    def test_simulator_build_marker_is_rejected(self):
        command=struct.pack('<IIIIII',0x32,24,7,0,0,0)
        data=struct.pack('<IIIIIIII',0xfeedfacf,0x0100000c,0,2,1,len(command),0,0)+command
        with self.assertRaises(ValueError): verify.check_macho(data)
    def test_other_cpu_is_rejected(self):
        data=struct.pack('<IIIIIIII',0xfeedfacf,0x01000007,0,2,0,0,0,0)
        with self.assertRaises(ValueError): verify.check_macho(data)
    def test_truncated_fat_header_is_rejected(self):
        with self.assertRaises((ValueError,struct.error)): verify.check_macho(b'\xca\xfe\xba\xbe'+b'\xff'*32)
    def test_simulator_bundle_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'fixture.zip'
            info={'CFBundleIdentifier':'org.elyra.Elyra','CFBundlePackageType':'APPL','UIDeviceFamily':[1,2],'CFBundleSupportedPlatforms':['iPhoneSimulator']}
            with zipfile.ZipFile(path,'w') as z: z.writestr('Payload/Elyra.app/Info.plist',plistlib.dumps(info))
            with self.assertRaises(ValueError): verify.verify(path)

class SignatureMetadataTests(unittest.TestCase):
    def fixture(self, entitlements=None, adhoc=True):
        if entitlements is None: entitlements={'com.apple.security.application-groups':['group.org.elyra.Elyra']}
        xml=plistlib.dumps(entitlements)
        cd=struct.pack('>IIII',0xfade0c02,16,0x20400,2 if adhoc else 0)
        xmlblob=struct.pack('>II',0xfade7171,len(xml)+8)+xml
        blob=struct.pack('>III',0xfade0cc0,28+len(cd)+len(xmlblob),2)+struct.pack('>IIII',0,28,5,28+len(cd))+cd+xmlblob
        return struct.pack('<IIIIIIII',0xfeedfacf,0x0100000c,0,2,1,16,0,0)+struct.pack('<IIII',0x1d,16,48,len(blob))+blob
    def test_actual_xml_slot_and_adhoc_flag_are_read(self):
        result=verify.signature_info(self.fixture())
        self.assertTrue(result['adhoc'])
        self.assertEqual(result['entitlements']['com.apple.security.application-groups'],['group.org.elyra.Elyra'])
    def test_certificate_flag_is_not_reported_as_adhoc(self):
        self.assertFalse(verify.signature_info(self.fixture(adhoc=False))['adhoc'])
    def test_missing_groups_are_not_fabricated(self):
        self.assertEqual(verify.signature_info(self.fixture({}))['entitlements'],{})
    def test_signature_outside_file_is_rejected(self):
        fixture=bytearray(self.fixture());struct.pack_into('<I',fixture,40,len(fixture)+1)
        with self.assertRaises(ValueError):verify.signature_info(fixture)
    def test_overlapping_blob_table_is_rejected(self):
        fixture=bytearray(self.fixture());struct.pack_into('>I',fixture,64,4)
        with self.assertRaises(ValueError):verify.signature_info(fixture)
    def test_non_dictionary_entitlements_are_rejected(self):
        with self.assertRaises(ValueError):verify.signature_info(self.fixture(['not-a-dictionary']))

if __name__=='__main__': unittest.main()
