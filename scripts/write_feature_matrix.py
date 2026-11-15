#!/usr/bin/env python3
import json
from pathlib import Path
r=Path(__file__).resolve().parents[1]
rows=[]
def row(name,location,description,dependency,special,risk,duplicate,module,progress,verification,local=False):
    status='本地功能已实现；具体测试见验证列' if local else '功能状态见进度；系统效果待真机验证'
    rows.append([name,location,description,dependency,status,'尚未验证（无 27 运行证据）','同一入口；系统效果待真机验证','同一入口；系统效果待真机验证',special,risk,duplicate,module,progress,verification])
for p in json.loads((r/'docs/audit/presets.json').read_text()):
    row(p['title'],'B: GestaltX/Capabilities.swift (`'+p['id']+'`)',p['detail'],'CacheExtra: '+', '.join('`'+k+'`' for k in p['keys']),'直接文件权限或签名 App Group；逐构建实际探测','高' if p['caution'] else '较高','A/B 重复' if p['id'] in ['dynamicIsland','aod','aodVibrancy','pwm','bootChime','chargeLimit','tapToWake','cameraControl','actionButton','collisionSOS','pencil','stageManager','ai','internal','storage','srd'] else 'B 独有','Capability / SystemConfigurationStore','保留原类型、拒绝猜值；不提供 Siri 通用替换' if p['id']=='siriOnDevice' else '设备读取、预设暂存、确认写入及回读已接入；需实际权限；本地编辑保留','catalog 源码定位；系统事务故障注入测试通过；逐项系统效果与恢复仍待真机验证')
    rows[-1][4:6]=['实验性：原生模块含 26 路径；逐构建权限与效果未验证','实验性：原生模块含 27 路径；无 27 真机证据']
entries=[
('设备配置读取','A: Tweaks/MobileGestalt/GestaltHelpers.swift; B: GestaltManager.swift','读取真实系统缓存，不能由导入文件代替','worse_query + signed App Group','需要系统容器访问','高','A/B','Compatibility','未迁移；当前只读导入文档','上游明确 26 不支持 MG；27 无真机证据'),
('全部字段浏览／递归容器','A: CustomKeyView.swift; B: GestaltDocument.swift, ContentView.swift','浏览全部可用 CacheExtra 以及根、数组、嵌套字典','Foundation plist','本地无特殊权限','低','A/B','DocumentEditor','已实现本地真实文档','8 类型往返与嵌套路径测试通过'),
('搜索字段与值','B: ContentView.swift; A: PlistViewer.swift','编辑器内递归内容搜索；全局搜索导入字段名称','索引 + plist','本地无','低','A/B','AreaView / DocumentEditor','已实现；全局字段结果递归索引并直接打开字段编辑器','Core 测试及 Apple 编译已通过；该交互尚待 UI 专项'),
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
('壁纸包与 .tendies 导入解析','A: PBHandler.swift; B: CustomizationFiles.swift / CustomizationThemes.swift','PB 三种 provider 结构、标识随机化、资源预览','libarchive(A) / ZIPFoundation(B)','仅解析无需系统权限','中','A/B','Appearance','已实现 ZIP/tendies 路径、CRC、有界离线检查及条目预览导出；尚未安装提供器','恶意路径/链接/CRC/加密/截断/大小测试通过；不是系统壁纸安装'),
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
('文本文件编辑','A: TextViewer.swift','受支持的 UTF-8 文件编辑','Foundation','实际文件权限','中','A','Tools','已实现受管理 UTF-8 文本编辑、BOM 保留、版本备份及恢复','8 项文本/文件事务测试通过；准确界面覆盖见 TEST_REPORT'),
('任意路径覆盖／移动／删除','A: OperationsView.swift','不能以沙盒逃逸授予权限','worse_query upstream','特殊访问','高','A 独有','FileAccess','不迁移任意系统目标；提供库回收站恢复','资产 path traversal 与 trash 恢复测试'),
('设备配对与连接','B: DeviceConnectionModel + Native/DeviceConsole','RPPairing、RSD、Lockdown、LocalDevVPN 指引','Rust idevice @7bd551c','配对记录/本地网络','中','B 独有','Tools','未迁移；保留前置条件说明','PIN/密钥不记日志的源码策略已记录'),
('设备信息／诊断','A: DeviceInfoHelpers; B: GXDeviceIdentity','系统版本/Build/硬件、公开进程信息','Darwin sysctl / ProcessInfo','公开信息无需特别权限','低','A/B','Diagnostics','已实现公开信息页面；系统服务诊断未迁移','基线 UI 运行通过；版本策略 Core 测试通过'),
('日志／调试导出','A: LogView; B: DeviceConsole','Elyra 记录本地操作；上游 exploit 日志不运行','operation records','本地无','低','A/B','History','本地列表/搜索及 JSON 导出已实现','持久化／并发 Core 测试'),
('Respring／自动 Respring','A: Respring.swift; B: NeoSpringView.swift','WebKit 资源耗尽；不是受支持系统 API','WebKit','系统行为不可靠','高','A/B','Tools','不迁移不可靠触发；入口解释限制','无实际触发'),
('全局搜索／收藏','新增；B 部分字段搜索','搜索分类、功能、字段；收藏首页显示','本地索引','无','低','统一新增','AreaView / Workspace','已实现嵌套字段直接定位','持久收藏 Core 待专项；UI 待测'),
('窗口与草稿独立','新增，B 单窗口 manager','每窗口导航、搜索与草稿；统一写入 actor','SceneStorage + actor','无','中','统一新增','RootView / Workspace','已实现基本状态；滚动位置未持久化','并发测试、草稿隔离测试通过；系统窗口待测'),
('响应式 iPhone/iPad 导航','新增重构','按真实宽高与大字级别切换；720/1100 渐进断点','NavigationSplitView / TabView','无','低','统一新增','DesignSystem','已实现布局策略；真实拖动窗口测试阻断','策略测试及基线 iPhone/iPad 旋转测试通过；Stage Manager 连续拖动仍待真机'),
('中英文／无障碍','B: Localizable.xcstrings；A 原英文','系统语言、字体、VoiceOver 标签与减少动态效果','lproj / SwiftUI','无','低','统一重构','Resources','中英文核心界面已实现；VoiceOver 和字体验收待测','静态资源检查；未完成辅助技术验收'),
('CI 与 IPA','A: ipabuild.sh; B: build.yml / build-ipa.sh','真实 arm64 archive、bundle/Mach-O 验证、SHA-256','macOS + Xcode','GitHub repo Actions 权限','中','统一重构','scripts / .github','仓库已推送；基线 Actions 成功生成真实 arm64 未签名 IPA','设备归档与 IPA 结构验证已通过；准确测试提交及最新结果见 TEST_REPORT')
]
local_words=['本地','PlistValue','DocumentEditor','元数据','备份','字段']
overrides={
 '设备配置读取': ('原生只读与读写权限探测已接入；失败显示实际原因；导入文件不能建立设备会话','SystemConfigurationStore / DeviceBackend；真实文件描述符；真机访问待测'),
 '设备身份与导出证明': ('设备会话与备份通过本机专用 Keychain 安装密钥及缓存 generation 绑定；导入证明/HMAC 导出未迁移','跨安装、旧 generation、替换 inode 拒绝测试通过；不声称工厂配置认证'),
 'Dynamic Island subtype': ('文档编辑器支持源码已有 subtype；设备写入受白名单和确认流程约束；没有通用圆角修复预设','原生编译及未知 subtype 拒绝测试；外观效果无真机验证'),
 'Artwork 自定义设备名': ('允许嵌套 Artwork 显示名字段；保护其他成员；无独立表单','generation/保护字段测试；设备显示效果待测'),
 '变更暂存与确认': ('本地和设备共用类型编辑器、差异预览；设备会话独立关联实时快照','stale revision 与多窗口事务测试通过；设备编辑完整 UI 流程待测'),
 '设备写入回读及失败恢复': ('系统读写、inode/revision 检查、写前备份、精确回读、回滚和显式中断恢复已实现','14 项系统事务测试含部分写入、回滚失败、跨安装和并发；硬件系统效果待测'),
 '首次自动备份': ('本地导入基准与设备直接捕获分开；每个设备安装/缓存 generation 首次捕获','真实临时文件读回与重开测试；不将捕获值称为出厂值'),
 '每次写入前备份／手动备份': ('设备与本地均在写前保存校验备份；设备编辑器支持手动备份','备份、校验、回滚与恢复测试通过'),
 '备份列表、来源、日期、导出': ('本地及设备备份均支持列表/来源/日期/导出；设备备份可离线查看、比对当前捕获，恢复另验写权限','本地导出、设备备份索引/完整性与只读检查测试；最新 Apple UI 覆盖见 TEST_REPORT'),
 '备份完整性／同文档恢复': ('本地按文档绑定；设备按本机专用 Keychain 安装密钥、generation 和 SHA-256 拒绝不匹配恢复','损坏、跨安装、跨缓存与原字节恢复测试通过'),
 'Respring／自动 Respring': ('首页提供手动、需确认的实验性注销设备；禁止写入/恢复期间执行；无自动注销','上游 WebKit 实现已编译；模拟器按钮禁用；未在真机触发'),
 '日志／调试导出': ('本地操作列表/搜索及 JSON 导出已实现；设备备份来源记录；原生 access token 不记日志；设备独立操作历史待完善','持久化/并发 Core 测试；不导出 Keychain 密钥或 sandbox token'),
 '全局搜索／收藏': ('嵌套字段直接定位、功能收藏；首页不再显示独立快捷入口','Core 索引测试；完整收藏 UI 待测'),
}
for e in entries:
 if e[0] in overrides: e=(*e[:8],*overrides[e[0]])
 row(*e,local=e[7] in ['PlistValue','Workspace','DocumentEditor','FilesView','AppEnvironment','BackupsView'])
row('Dynamic Island 配置检查与局部恢复','Elyra/Core/DynamicIsland.swift','检查导入标记/Artwork 类型，局部恢复导入基准中的两个 DI 字段；设备编辑器独立提供实时写入与完整备份恢复','typed plist + verified baseline','本地无；设备需实际系统访问','中','统一新增','DynamicIslandEngine','本地检查已实现；可进入设备配置；不猜 subtype 默认值，不声称系统形状修复','14 项 DI/观察/迁移测试及系统事务测试；外观效果未验证',True)
row('灵动岛外观记录','Elyra/Features/IslandObservations.swift','记录运行环境、方向、活动、形状与圆角；媒体播放状态可选；持久化并导出 JSON','RuntimeDeviceContext / Workspace','无','低','统一新增','DynamicIsland Lab','已实现；模拟器记录自动标注，不作为系统证据','观察持久化、版本关联和导出边界测试通过',True)
row('文本文件版本与中断恢复','Elyra/Core/TextAsset.swift, Workspace.swift','原始字节备份、原子保存、版本冲突保护及 asset journal 重启恢复','SHA-256 / actor / journal','本地无','中','统一新增','AssetBackups','已实现 UTF-8 文件及文件备份恢复','BOM/CRLF/no-op/空文本/损坏备份/跨文件/中断恢复测试通过',True)
row('语言选择','Elyra/App/LocalizationStore.swift; Features/LanguageSettingsView.swift','简体中文、English、跟随系统；保存偏好并同步全部窗口','SwiftUI locale / bundled resources','应用偏好','低','统一新增','Settings / Localization','已实现语言设置；功能名称使用统一术语','语言策略 Core 测试通过；真实切换与重启保留 UI 结果见 TEST_REPORT',True)
row('关于与账号卡片','Elyra/Features/AboutView.swift','关于页直接显示 GitHub、抖音、小红书卡片；独立开源许可页','SafariServices','打开指定公开主页','低','统一新增','Settings / About','已实现；主界面不展示源码审计叙述；保留法定版权与许可','模拟器覆盖三个卡片直接可达；不自动打开外部主页',True)
row('配置方案','Elyra/Core/ConfigurationPlan.swift; Features/ConfigurationPlansView.swift','按功能 ID 与应用/恢复动作保存和分享；同一快照合并，一次差异确认、备份和事务写入；不携带设备原值','JSON / Workspace / SystemConfigurationStore','编辑导入导出无需系统权限；应用需实际写权限','中','统一新增','ConfigurationPlans','已实现方案管理与批量事务；无未经验证的原值导入','版本/大小/重复/未知 ID、原子存储、批量回滚及单次写入测试；Apple 验证见 TEST_REPORT',True)
row('窗口与显示检测','Elyra/Features/DisplayDiagnosticsView.swift','读取当前 UIWindowScene 的窗口/安全区/显示缩放/像素/最高帧率/EDR 余量；可选测量本应用回调频率','UIKit / CADisplayLink；公开 API','无特殊权限，只读','低','统一新增','Tools / Diagnostics','已实现；回调频率不等同面板扫描率或 PWM','Apple 文档核验与模拟器界面验证；真机/外接显示器待验',True)
headers=['功能名称','现有实现位置','功能说明','底层依赖','iOS 26 状态','iOS 27 状态','iPhone','iPad','特殊权限','风险','重复实现','Elyra 模块','实现进度','验证方法和结果']
preamble='''# Elyra 功能并集与迁移矩阵

审计快照：2026-11-14 UTC。A = Erosion `12c0a2d00c444c9b09112608b47d4d6c10e0df14`；B = GestaltX `d1d5473734440e8f2e797494ac373427c02fd674`。

这是实际进度表，不是完成声明。0.3 已接入固定版本的原生 MobileGestalt 访问模块及受限设备写入；只针对实时捕获的设备配置，实际权限探测通过后才能写入。iOS 26/27 的**系统行为均无本次真机验证**；上游支持声明不继承为 Elyra 结论。iPhone/iPad 使用相同目录、编辑器及事务层；Apple CI 结果见 TEST_REPORT。UI 最低目标 iOS 17；已运行 26.2 模拟器，27 SDK/真机仍待验证。外观资源安装等其他模块的未迁移状态分别列明，不能从 MobileGestalt 后端推定可用。

位置中 B 的无目录 Swift 文件位于 `GestaltX/`；A 的短目录位于 `Erosion/`。精确路径、散列和声明参见 [source-inventory.json](audit/source-inventory.json)。完整风险与审查边界见 [SOURCE_AUDIT.md](SOURCE_AUDIT.md)。预设目录来自实际源码而非 README。按并集列出，重叠统一成 Capability/Workspace 引擎，不拼接原 UI。

'''
def escape(cell): return str(cell).replace('|','\\|').replace('\n',' ')
text=preamble+'| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'
text+='\n'.join('| '+' | '.join(map(escape,cells))+' |' for cells in rows)+'\n'
(r/'docs/FEATURE_MATRIX.md').write_text(text)
(r/'docs/audit/feature-matrix.json').write_text(json.dumps([dict(zip(headers,cells)) for cells in rows],ensure_ascii=False,indent=2)+'\n')
print(f'{len(rows)} feature matrix rows')
