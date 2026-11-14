#!/usr/bin/env python3
"""Generate the committed Xcode project using only Python's standard library."""
import hashlib, json, plistlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
objects = {}
def uid(name): return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def add(name, text):
    key=uid(name); objects[key]=text; return key
def quoted(v): return json.dumps(str(v))
def seq(ids): return '(' + ', '.join(ids) + (',' if ids else '') + ')'
def ref(path, kind): return add('ref:'+path, f'{{isa = PBXFileReference; lastKnownFileType = {kind}; path = {quoted(path)}; sourceTree = SOURCE_ROOT; }}')
def build(path, kind):
    r=ref(path,kind); return r,add('build:'+path,f'{{isa = PBXBuildFile; fileRef = {r}; }}')
app_sources=[]; test_sources=[]; source_refs=[]; resources=[]
for p in sorted((ROOT/'Elyra').rglob('*.swift')):
    r,b=build(str(p.relative_to(ROOT)),'sourcecode.swift'); source_refs.append(r); app_sources.append(b)
for p in sorted((ROOT/'Elyra/Native').glob('*.m')):
    r,b=build(str(p.relative_to(ROOT)),'sourcecode.c.objc'); source_refs.append(r); app_sources.append(b)
for p in sorted((ROOT/'Elyra/Native').glob('*.h')):
    source_refs.append(ref(str(p.relative_to(ROOT)),'sourcecode.c.h'))
r,b=build('UITests/ElyraUITests.swift','sourcecode.swift'); source_refs.append(r); test_sources.append(b)
for p in ['Elyra/Resources/Assets.xcassets','Elyra/Resources/Licenses','Elyra/Resources/PrivacyInfo.xcprivacy']:
    r,b=build(p, 'folder.assetcatalog' if p.endswith('xcassets') else 'folder' if p.endswith('Licenses') else 'text.xml');source_refs.append(r);resources.append(b)
locale_refs=[]
for lang in ['en','zh-Hans']:
    locale_refs.append(add('locale:'+lang, '{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = '+quoted(lang)+'; path = '+quoted('Elyra/Resources/'+lang+'.lproj/Localizable.strings')+'; sourceTree = SOURCE_ROOT; }'))
vg=add('locales', '{isa = PBXVariantGroup; children = '+seq(locale_refs)+'; name = Localizable.strings; sourceTree = "<group>"; }')
source_refs.append(vg);resources.append(add('locales-build','{isa = PBXBuildFile; fileRef = '+vg+'; }'))
app_product=add('app-product','{isa = PBXFileReference; explicitFileType = wrapper.application; path = Elyra.app; sourceTree = BUILT_PRODUCTS_DIR; }')
test_product=add('test-product','{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = ElyraUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }')
products=add('products','{isa = PBXGroup; children = '+seq([app_product,test_product])+'; name = Products; sourceTree = "<group>"; }')
group=add('main-group','{isa = PBXGroup; children = '+seq(source_refs+[products])+'; sourceTree = "<group>"; }')
def phase(name,isa,files): return add(name,'{isa = '+isa+'; buildActionMask = 2147483647; files = '+seq(files)+'; runOnlyForDeploymentPostprocessing = 0; }')
def settings(name,values): return add(name,'{isa = XCBuildConfiguration; name = '+name.rsplit('-',1)[-1]+'; buildSettings = {'+' '.join(k+' = '+quoted(v)+';' for k,v in values.items())+'}; }')
common={'IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','SDKROOT':'iphoneos','ENABLE_USER_SCRIPT_SANDBOXING':'YES','SWIFT_STRICT_CONCURRENCY':'complete'}
app={'PRODUCT_NAME':'Elyra','PRODUCT_BUNDLE_IDENTIFIER':'org.elyra.Elyra','INFOPLIST_FILE':'Elyra/Resources/Info.plist','TARGETED_DEVICE_FAMILY':'1,2','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME':'AccentColor','CODE_SIGN_STYLE':'Automatic','CURRENT_PROJECT_VERSION':'2','MARKETING_VERSION':'0.4.0','SWIFT_OBJC_BRIDGING_HEADER':'Elyra/Native/Elyra-Bridging-Header.h','CODE_SIGN_ENTITLEMENTS':'Elyra/Resources/Elyra.entitlements','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks','GENERATE_INFOPLIST_FILE':'NO','SUPPORTS_MACCATALYST':'NO','SWIFT_EMIT_LOC_STRINGS':'YES'}
test={'PRODUCT_NAME':'ElyraUITests','PRODUCT_BUNDLE_IDENTIFIER':'org.elyra.ElyraUITests','GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'Elyra','TARGETED_DEVICE_FAMILY':'1,2','CODE_SIGN_STYLE':'Automatic'}
def config_list(name,base):
    configs=[]
    for mode in ['Debug','Release']:
        v=base.copy();v.update({'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym','ONLY_ACTIVE_ARCH':'YES' if mode=='Debug' else 'NO'})
        if mode=='Debug': v['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'
        configs.append(settings(name+'-'+mode,v))
    return add(name+'-configlist','{isa = XCConfigurationList; buildConfigurations = '+seq(configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }')
project_id=uid('project');app_id=uid('app-target');test_id=uid('ui-target')
proxy=add('test-proxy','{isa = PBXContainerItemProxy; containerPortal = '+project_id+'; proxyType = 1; remoteGlobalIDString = '+app_id+'; remoteInfo = Elyra; }')
dep=add('test-dep','{isa = PBXTargetDependency; target = '+app_id+'; targetProxy = '+proxy+'; }')
zip_ref=add('zip-reference','{isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/weichsel/ZIPFoundation.git"; requirement = {kind = revision; revision = "22787ffb59de99e5dc1fbfe80b19c97a904ad48d"; }; }')
zip_product=add('zip-product','{isa = XCSwiftPackageProductDependency; package = '+zip_ref+'; productName = ZIPFoundation; }')
zip_build=add('zip-build','{isa = PBXBuildFile; productRef = '+zip_product+'; }')
app_phases=[phase('app-sources' ,'PBXSourcesBuildPhase',app_sources),phase('app-frameworks','PBXFrameworksBuildPhase',[zip_build]),phase('app-resources','PBXResourcesBuildPhase',resources)]
test_phases=[phase('test-sources','PBXSourcesBuildPhase',test_sources),phase('test-frameworks','PBXFrameworksBuildPhase',[])]
add('app-target','{isa = PBXNativeTarget; buildConfigurationList = '+config_list('app',app)+'; buildPhases = '+seq(app_phases)+'; buildRules = (); dependencies = (); name = Elyra; packageProductDependencies = '+seq([zip_product])+'; productName = Elyra; productReference = '+app_product+'; productType = "com.apple.product-type.application"; }')
add('ui-target','{isa = PBXNativeTarget; buildConfigurationList = '+config_list('test',test)+'; buildPhases = '+seq(test_phases)+'; buildRules = (); dependencies = '+seq([dep])+'; name = ElyraUITests; productName = ElyraUITests; productReference = '+test_product+'; productType = "com.apple.product-type.bundle.ui-testing"; }')
add('project','{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {'+app_id+' = {SystemCapabilities = {com.apple.ApplicationGroups.iOS = {enabled = 1; }; }; }; '+test_id+' = {TestTargetID = '+app_id+'; }; }; }; buildConfigurationList = '+config_list('project',common)+'; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, "zh-Hans", Base); mainGroup = '+group+'; productRefGroup = '+products+'; projectDirPath = ""; projectRoot = ""; packageReferences = '+seq([zip_ref])+'; targets = '+seq([app_id,test_id])+'; }')
p=ROOT/'Elyra.xcodeproj';p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+ '\n'.join(k+' = '+v+';' for k,v in sorted(objects.items()))+'\n}; rootObject = '+project_id+'; }\n')
schemes=p/'xcshareddata/xcschemes';schemes.mkdir(parents=True,exist_ok=True)
def bref(id,name,file): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{id}" BuildableName="{file}" BlueprintName="{name}" ReferencedContainer="container:Elyra.xcodeproj"/>'
schemes.joinpath('Elyra.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{bref(app_id,'Elyra','Elyra.app')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{bref(test_id,'ElyraUITests','ElyraUITests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{bref(app_id,'Elyra','Elyra.app')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0">{bref(app_id,'Elyra','Elyra.app')}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
info={'CFBundleDevelopmentRegion':'en','CFBundleDisplayName':'Elyra','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleInfoDictionaryVersion':'6.0','CFBundleName':'Elyra','CFBundlePackageType':'APPL','CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)','LSRequiresIPhoneOS':True,'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':True},'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'UIRequiresFullScreen':False,'ITSAppUsesNonExemptEncryption':False}
(ROOT/'Elyra/Resources/Info.plist').write_bytes(plistlib.dumps(info,sort_keys=False))
privacy={'NSPrivacyTracking':False,'NSPrivacyCollectedDataTypes':[],'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults','NSPrivacyAccessedAPITypeReasons':['CA92.1']}]}
(ROOT/'Elyra/Resources/PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(privacy))
print('Generated Elyra.xcodeproj (app + UI test target, universal iOS 17+)')
