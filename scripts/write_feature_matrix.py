#!/usr/bin/env python3
import json
from pathlib import Path
r=Path(__file__).resolve().parents[1]
rows=[]
def row(name,location,description,dependency,special,risk,duplicate,module,progress,verification,local=False):
    status='本地可用；系统行为未验证' if local else '系统操作未验证／当前无后端'
    rows.append([name,location,description,dependency,status,status,'同一入口；系统效果待真机验证','同一入口；系统效果待真机验证',special,risk,duplicate,module,progress,verification])
for p in json.loads((r/'docs/audit/presets.json').read_text()):
    row(p['title'],'B: GestaltX/Capabilities.swift (`'+p['id']+'`)',p['detail'],'CacheExtra: '+', '.join('`'+k+'`' for k in p['keys']),'系统写入需要授权后端','高' if p['caution'] else '较高','A/B 重复' if p['id'] in ['dynamicIsland','aod','aodVibrancy','pwm','bootChime','chargeLimit','tapToWake','cameraControl','actionButton','collisionSOS','pencil','stageManager','ai','internal','storage','srd'] else 'B 独有','Capability / System','已迁移本地预设；siriOnDevice 保留原类型、拒绝猜值；系统写入未迁移' if p['id']=='siriOnDevice' else '本地暂存与差异预览已实现；系统写入阻断','catalog 源码定位；公共引擎测试。仅 DI/Siri 有专项预设测试；其余效果未验证',True)
entries=[
('设备配置读取','A: Tweaks/MobileGestalt/GestaltHelpers.swift; B: GestaltManager.swift','读取真实系统缓存，不能由导入文件代替','worse_query + signed App Group','需要系统容器访问','高','A/B','Compatibility','未迁移；当前只读导入文档','上游明确 26 不支持 MG；27 无真机证据'),
('全部字段浏览／递归容器','A: CustomKeyView.swift; B: GestaltDocument.swift, ContentView.swift','浏览全部可用 CacheExtra 以及根、数组、嵌套字典','Foundation plist','本地无特殊权限','低','A/B','DocumentEditor','已实现本地真实文档','8 类型往返与嵌套路径测试通过'),
('搜索字段与值','B: ContentView.swift; A: PlistViewer.swift','编辑器内递归内容搜索；全局搜索导入字段名称','索引 + plist','本地无','低','A/B','AreaView / DocumentEditor','已实现；全局字段结果递归索引并直接打开字段编辑器','Core 可编译；UI 待 Xcode'),
('添加自定义字段','A: CustomKeyView.swift; B: FieldDraft','8 类型完整 XML 值输入；重复字段拒绝覆盖','PlistValue','本地无','中','A/B','DocumentEditor','已实现','类型与异常输入测试通过'),
('重命名字段','B: field editor','原子重命名，保留原类型','字段身份','本地无','中','A/B','DocumentEditor','已实现字典字段重命名，复制草稿后统一替换','源码语法解析通过；重命名 UI 未运行'),
('删除字段与记录缺失值','B: GestaltDocument.swift; A: PlistManager.swift','删除不等于置零；恢复应保留原本缺失状态','typed diff','本地无','中','A/B','PlistValue','本地实现','缺失原值与删除测试通过'),
('String','B: PlistValueKind; A: ModifyItemPage.swift','字符串编辑','Foundation','无','低','A/B','PlistValue','已实现','8 类型往返测试'),
('Integer','B: PlistValueKind','带符号 64 位整数，拒绝溢出','NSNumber','无','中','A/B','PlistValue','已实现；无符号超范围整数拒绝','超 2^53 整数测试'),
('Real','B: PlistValueKind','有限浮点数，拒绝 NaN/Infinity','NSNumber','无','中','A/B','PlistValue','已实现','非有限值测试'),
('Boolean','B: PlistValueKind','类型与数值 0/1 严格区分','CoreFoundation','无','中','A/B','PlistValue','已实现','bool/int/real 类型差异测试'),
('Data','B: PlistValueKind','XML base64 编码二进制数据','Foundation','无','中','A/B','PlistValue','已实现','8 类型往返测试'),
('Date','B: PlistValueKind','XML 日期；原文本不变时保留精确原值','Foundation','无','中','A/B','FieldEditor','已实现，尚缺 UI 时间精度专项','往返测试；精度专项待补'),
('Array','B: PlistValueKind','递归浏览；XML 编辑、索引删除','Foundation','无','中','A/B','PlistValue','已实现','递归索引与越界测试'),
('Dictionary','B: PlistValueKind','递归字典编辑、添加与删除','Foundation','无','中','A/B','PlistValue','已实现','嵌套与 diff 路径测试'),
('plist 导入','B: DirectFileImports.swift / SharedPlistInbox.swift','系统文件选择器；有界读取并复制进工作区','security-scoped URL','用户选择文件','低','A/B','AppEnvironment','本地已实现；不赋予设备归属证明','损坏/超大小测试；文件选择 UI 待测'),
('plist 导出','A: Shareinator.swift; B: TemporaryExport.swift','导出真实草稿或校验后的备份','FileDocument','用户选择目标','低','A/B','DocumentEditor / Backups','已实现','编码往返通过；fileExporter 未运行'),
('分享扩展／共享收件箱','B: ShareExtension/, Shared/','持久交接、取消、签名 App Group 发现','Extension + App Groups','共同签名组','中','B 独有','Extensions','未迁移；文件选择器不是分享扩展替代品','审阅原实现与组依赖'),
('设备身份与导出证明','B: DevicePlistIdentity.swift, DeviceBoundPlist.swift','至少两个独立设备标识；device-only Keychain HMAC','Security / CryptoKit','Keychain / device access','高','B 更完善','ConfigurationEngine','未迁移；任何导入文件都不被当作设备原始配置','源码审查，未进行设备身份测试'),
('Dynamic Island subtype','A: GestaltView.swift; B: ContentView.swift category display','ArtworkDeviceSubType 选择，不是像素宽高／圆角','ArtworkTraits','系统写入后端','高','A/B 有冲突','DynamicIsland','仅展示读到的本地值；未提供未经验证系统预设','A 2436/B 2556 差异已记录'),
('Artwork 自定义设备名','A: GestaltView.swift; B: GestaltDocument.swift','仅修改 Artwork 名称成员，避免覆盖 subtype','ArtworkTraits','系统写入后端','中','A/B','System','字段可本地编辑；专用表单未迁移','公共嵌套编辑保留成员测试'),
('地区代码','A: mgRegionRestrictionsBinding; B: RegionPreset','RegionCode 与销售后缀独立','CacheExtra','系统写入后端','高','A/B','System / Intelligence','原始字段可本地编辑；专用地区预设未迁移','不能保证服务端 AI/eSIM 资格'),
('销售地区／型号号码','B: RegionPreset, ModelPreset','销售后缀与监管型号，不能凭空生成原值','GestaltDocument','同设备可信原始值','高','A/B 部分重叠','System','尚未迁移专用预设','上游地区、eSIM 故障报告已记录'),
('硬件 Product/Board/CPU 伪装','A: GestaltView.swift / mgApply','硬件身份伪装存在 Face ID 等已知风险','CacheExtra','系统写入后端','严重','A；B 改为恢复流程','System','不启用危险系统伪装；保留审计记录','Issue #128 与原警告'),
('硬件身份恢复','B: GestaltManager.restoreHardwareIdentity','核对 kernel product/board、原 CPU、CacheData/UUID/version','可信同设备原始文件','真实设备访问','高','B 独有','Backups','未迁移；本地备份不得冒充可信原始文件','源码追踪恢复前置条件'),
('iPadOS UI/设备身份二进制修改','A: GestaltStore.mgSetiPadOS','正则推断 CacheData 偏移并切换身份字节','固定搜索区间','系统写入后端','严重','A 独有','System','未迁移不可靠二进制算法','已识别字节布局与软砖警告'),
('green-tea / not-green-tea / FaceTime Audio','B: DeviceCacheOptions.swift','依据设备库描述符匹配缓存布局，仅允许目标字节','Mach-O descriptors','设备库与写入后端','高','B 独有','System','未迁移；不复用固定偏移','静态分析布局拒绝策略'),
('WAPI','B: DeviceCacheOptions.swift','独立缓存标记与可信原始恢复','动态缓存布局','设备库与写入后端','高','B 独有','System','未迁移','源码，未真机验证'),
('变更暂存与确认','B: GestaltManager + ContentView','编辑不立即写入，确认前展示类型和值','snapshot / diff','本地无','中','B 更完善','Workspace / DocumentEditor','本地已实现','原值/目标值差异，stale revision 测试'),
('设备写入回读及失败恢复','B: GestaltManager.commit; A: WriteHelpers.swift','备份、重读并验证全文件／类型，失败回滚','worse_query','特殊系统访问','高','A/B','ConfigurationEngine','仅本地实现；系统实现未迁移','本地并发/备份失败/字节恢复测试'),
('首次自动备份','B: GestaltManager; A: savedGestaltURL','Elyra 记录导入基准，不声称出厂值','文件 + digest','本地无','低','A/B','Workspace','已实现本地','真实字节对比与重开测试'),
('每次写入前备份／手动备份','B: saveBackup / backup','先保存并校验备份再写入','SHA-256','本地无','低','B 更完善','Workspace','已实现本地','备份失败禁止写入测试'),
('备份列表、来源、日期、导出','B: BackupRecord + backupExportData','本地文档标识、来源、日期、大小、散列','JSON + plist','本地无','低','B','BackupsView','已实现本地','元数据重开与导出编码'),
('备份完整性／同文档恢复','B: backupData / restore','拒绝损坏、缺失及其他文档备份','SHA-256','本地无','中','B 更完善','Workspace','已实现本地；hash 不是设备认证','同大小篡改／跨文档拒绝测试'),
('单预设恢复／原值记录','B: OriginalValues / Capability.apply','保留原值、原类型及不存在状态','可信原始快照','可信原始数据','高','B 更完善','Backups','可完整恢复本地快照；专用单预设恢复未迁移','缺失值测试；系统无验证'),
('备份删除','B: deleteBackup','保留可恢复元数据直到 payload 删除','文件管理','无','中','B','Backups','尚未提供备份删除 UI','不删除原始基准'),
('MobileGestalt 缓存删除重置','A: GestaltView.swift reset','删除缓存强制重建；上游警告软砖风险','系统文件删除','系统访问','严重','A 独有','System','不迁移破坏性重置','明确不可用，不伪造默认值'),
('壁纸包与 .tendies 导入解析','A: PBHandler.swift; B: CustomizationFiles.swift / CustomizationThemes.swift','PB 三种 provider 结构、标识随机化、资源预览','libarchive(A) / ZIPFoundation(B)','仅解析无需系统权限','中','A/B','Appearance','仅原始包存储与导出；尚未解析／安装描述符','不把原始文件存储称为完成导入壁纸'),
('PosterBoard 应用／移除／刷新','A: PosterBoardView; B: CustomizationStore','安装记录、目录散列、受控移除与刷新','PosterBoard container','特殊容器访问','高','A/B','Appearance','未迁移系统安装','B 验证比 A 完善，待授权后端'),
('Collections 重置','A: PosterBoardView.swift','清除集合缓存，可能丢失用户数据','PosterBoard prefs','系统容器访问','高','A 独有','Appearance','不提供破坏性系统清除','审计原删除路径'),
('拨号键盘图片','A: KeypadManager.swift / KeypadView.swift','12 按键、亮暗 mask、图片预览及替换','TelephonyUI cache','Phone 容器访问','高','A 独有','Appearance','仅图片素材管理；系统替换未迁移','12 键/6 文件变体源码追踪'),
('键盘尺寸／圆形裁剪／主题包','A: KeypadManager.swift','150/205/225/custom，50...2500 边界、归档识别','UIKit / libarchive','本地加工无；应用需容器访问','中','A 独有','Appearance','未迁移加工/主题识别','原图缓存、尺寸上限、导入匹配已识别'),
('启动图目录与替换','B: LaunchArtworkCatalog/Files/Images/Store','应用枚举、PNG 编码、inode 原值与回读','LaunchServices + app container','跨容器访问','高','B 独有','Appearance','素材可预览导出；系统替换未迁移','原生模块和 rollback 路径已审阅'),
('启动图原分辨率保存到照片','B: LaunchArtworkImages.swift / LaunchArtworkViews.swift','Photos 保存真实原图','Photos permission','照片写入权限','低','B 独有','Appearance','未迁移；可使用 Quick Look 分享导出','非同等于 Photos 保存实现'),
('应用通知音替换／转码','B: AppSoundCodec/Files/Store/Views','音频导入、格式转换、文件发现、备份恢复','AVFoundation + container','跨容器访问','高','B 独有','Appearance','仅原音频存储、Quick Look；转码/系统替换未迁移','文件校验与恢复算法源码追踪'),
('通知音捕获与路径解析','B: NotificationSoundCaptureModel/LogParser','通过配对 syslog 关联应用与声音路径','Rust DeviceConsole + syslog_relay','配对与隧道','中','B 独有','Tools','未迁移','不启动未知设备服务'),
('锁屏底部文字','A: ConfigView; B: SystemSettingsStore','SharedDeviceConfiguration 的 footnote；原始文件事务','配置描述文件目录','系统配置访问','高','A/B','Appearance','入口与限制已实现；系统写入未迁移','与监督状态修改分离'),
('监督状态／组织名称修改','A: ConfigView.swift','修改 CloudConfigurationDetails / 监督标记','设备管理配置','未经授权管理修改','严重','A 独有','无可执行模块','按用户要求排除未经授权管理配置修改','明确不运行、不保留隐蔽开关'),
('文件目录浏览与搜索','A: FileBrowserView.swift','实际权限范围内目录／文件搜索','Foundation','所选目录/文件权限','低','A','FilesView','只实现受管理库文件搜索；目录层级浏览待迁移','资产真实文件测试，完整目录浏览未完成'),
('文件元数据／预览／导入导出','A: InfoViewer / TextViewer / FileHelpers','实际文件字节、名称、日期、大小、hash、Quick Look','FileDocument / QuickLook','文件选择授权','低','A','FilesView','已实现本地','文件真实读回通过；Quick Look UI 待测'),
('文本文件编辑','A: TextViewer.swift','受支持的 UTF-8 文件编辑','Foundation','实际文件权限','中','A','Tools','尚未迁移文本编辑器；plist 编辑已实现','记录为未完成'),
('任意路径覆盖／移动／删除','A: OperationsView.swift','不能以沙盒逃逸授予权限','worse_query upstream','特殊访问','高','A 独有','FileAccess','不迁移任意系统目标；提供库回收站恢复','资产 path traversal 与 trash 恢复测试'),
('设备配对与连接','B: DeviceConnectionModel + Native/DeviceConsole','RPPairing、RSD、Lockdown、LocalDevVPN 指引','Rust idevice @7bd551c','配对记录/本地网络','中','B 独有','Tools','未迁移；保留前置条件说明','PIN/密钥不记日志的源码策略已记录'),
('设备信息／诊断','A: DeviceInfoHelpers; B: GXDeviceIdentity','系统版本/Build/硬件、公开进程信息','Darwin sysctl / ProcessInfo','公开信息无需特别权限','低','A/B','Diagnostics','已实现公开信息页面；系统服务诊断未迁移','UI 未运行，版本策略 Core 测试通过'),
('日志／调试导出','A: LogView; B: DeviceConsole','Elyra 记录本地操作；上游 exploit 日志不运行','operation records','本地无','低','A/B','History','本地列表/搜索实现；日志导出未提供','持久化／并发 Core 测试'),
('Respring／自动 Respring','A: Respring.swift; B: NeoSpringView.swift','WebKit 资源耗尽；不是受支持系统 API','WebKit','系统行为不可靠','高','A/B','Tools','不迁移不可靠触发；入口解释限制','无实际触发'),
('全局搜索／收藏','新增；B 部分字段搜索','搜索分类、功能、字段；收藏首页显示','本地索引','无','低','统一新增','AreaView / Workspace','已实现嵌套字段直接定位','持久收藏 Core 待专项；UI 待测'),
('窗口与草稿独立','新增，B 单窗口 manager','每窗口导航、搜索与草稿；统一写入 actor','SceneStorage + actor','无','中','统一新增','RootView / Workspace','已实现基本状态；滚动位置未持久化','并发测试、草稿隔离测试通过；系统窗口待测'),
('响应式 iPhone/iPad 导航','新增重构','按真实宽高与大字级别切换；720/1100 渐进断点','NavigationSplitView / TabView','无','低','统一新增','DesignSystem','已实现布局策略；真实拖动窗口测试阻断','320...1600 逐点策略测试，不等于视觉验证'),
('中英文／无障碍','B: Localizable.xcstrings；A 原英文','系统语言、字体、VoiceOver 标签与减少动态效果','lproj / SwiftUI','无','低','统一重构','Resources','中英文核心界面已实现；VoiceOver 和字体验收待测','静态资源检查；未完成辅助技术验收'),
('CI 与 IPA','A: ipabuild.sh; B: build.yml / build-ipa.sh','真实 arm64 archive、bundle/Mach-O 验证、SHA-256','macOS + Xcode','GitHub repo Actions 权限','中','统一重构','scripts / .github','已配置，未运行；当前 token 创建仓库失败','本地静态检查；无 IPA 产物')
]
local_words=['本地','PlistValue','DocumentEditor','元数据','备份','字段']
for e in entries:
 row(*e,local=e[7] in ['PlistValue','Workspace','DocumentEditor','FilesView','AppEnvironment','BackupsView'])
headers=['功能名称','现有实现位置','功能说明','底层依赖','iOS 26 状态','iOS 27 状态','iPhone','iPad','特殊权限','风险','重复实现','Elyra 模块','实现进度','验证方法和结果']
preamble='''# Elyra 功能并集与迁移矩阵

审计快照：2026-11-14 UTC。A = Erosion `12c0a2d00c444c9b09112608b47d4d6c10e0df14`；B = GestaltX `d1d5473734440e8f2e797494ac373427c02fd674`。

这是实际进度表，不是完成声明。iOS 26/27 的**系统行为均无本次真机验证**；上游的支持声明不继承为 Elyra 结论。iPhone/iPad 使用相同目录与业务代码；“同一入口”是源码实现事实，UI 尚未经 Xcode 构建/运行。系统写入无授权后端，因此全部阻断。UI 最低目标 iOS 17，26/27 SDK/构建/设备均待验证。

位置中 B 的无目录 Swift 文件位于 `GestaltX/`；A 的短目录位于 `Erosion/`。精确路径、散列和声明参见 [source-inventory.json](audit/source-inventory.json)。完整风险与审查边界见 [SOURCE_AUDIT.md](SOURCE_AUDIT.md)。预设目录来自实际源码而非 README。按并集列出，重叠统一成 Capability/Workspace 引擎，不拼接原 UI。

'''
def escape(cell): return str(cell).replace('|','\\|').replace('\n',' ')
text=preamble+'| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'
text+='\n'.join('| '+' | '.join(map(escape,cells))+' |' for cells in rows)+'\n'
(r/'docs/FEATURE_MATRIX.md').write_text(text)
(r/'docs/audit/feature-matrix.json').write_text(json.dumps([dict(zip(headers,cells)) for cells in rows],ensure_ascii=False,indent=2)+'\n')
print(f'{len(rows)} feature matrix rows')
