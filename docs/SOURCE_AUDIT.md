# 上游源码审计与风险记录

审查日期：2026-11-14 UTC。两个仓库均通过实际 `git clone` 获取，非仅阅读 README。

| 仓库 | 分支 HEAD SHA | 跟踪文件数 |
| --- | --- | --- |
| https://github.com/jailbreakdotparty/Erosion | `12c0a2d00c444c9b09112608b47d4d6c10e0df14` | 95 |
| https://github.com/huamidev/GestaltX | `d1d5473734440e8f2e797494ac373427c02fd674` | 367 |

文件清单、每个文件的 SHA-256、源码声明和敏感操作定位保存在 [source-inventory.json](audit/source-inventory.json)。`scripts/audit_upstreams.py` 可从相邻 `upstream/` 克隆重新生成。此清单覆盖全部 git 跟踪文件；**清单生成不是逐行人工安全证明**。审计中深入审阅了下述关键路径；全部 UI/本地化/第三方 vendored Rust 的逐行审计尚未完成。未执行上游逃逸代码或设备修改。

## 文档、更新、Issues

Erosion README 顶部声称的 26.x 范围与其 Supported Versions 小节并不完全一致；FAQ 明确说明 26 无法写 MobileGestalt。`WorseQuerySwift.grantAccess` 只对特定 AppGroup 路径开启 26 特殊模式，不能推导为系统缓存访问可用。最近提交 `12c0a2d` 修复持久写入，`d1eb21f` 改用 pathleak/libarchive 并添加 GPLv3。未发现独立 CHANGELOG。

GestaltX 最新 HEAD changelog 为 1.1.1，新增配对与通知声音功能。README 仍显示 1.0.6，不能用 README 代替完整功能判断。`VersionSupport.contains` 仅检查 major == 27；这不是逐 build 验证策略。Elyra 不继承该宽泛成功判断。

GitHub issues/release API 已实际读取全部可访问分页：Erosion issues 返回空数组；GestaltX 返回 153 条 issue/PR 项。原始快照在 `docs/audit/*issues.json`、`*releases.json`；关键 issue 的评论快照在 `selected-issue-comments.json`（非所有 issue 评论完整审计）；issue 是用户报告，不是已复现事实。重点包括：

- #19：MG 可读但 O_RDWR 被拒；#82/#29：签名 App Group 问题；#152：27.0.1 读取失败。证明“主版本受支持”不能保证实际访问。
- #19 后续评论也报告同一设备/构建在 Feather 独立安装后 O_RDWR 成功，维护者建议独立安装并保留有效 App Group；这是一条特定条件下的上游成功报告，不是 Elyra 已验证结果。#29 评论关联 #47 的多 App Group 尝试修复。
- #141：DI 造成状态栏与刘海重叠；#125：DI 后显示缩放异常；#79/#105：Air subtype 请求。没有形成 iPad 整体外观修复证据。
- #128/#146：Face ID 恢复及本地化修复；#98：端侧 Siri 不应被泛化类型覆盖。
- #49：InternalBuild 是全局内部构建标记，不是仅存储分类。
- #93：OS 更新导致 CacheData 布局／恢复失败；#131-140：UUID 大小写、日期尾随字符、备份文件名、差异性能与编辑保留修复。
- #143：tendies 导入失败；#127：壁纸删除问题；#17/#21：发布 IPA 缺可执行文件／签名信息。Elyra 的 IPA 检查不能只检查 ZIP 名称。
- #144/#145/#26：AI 下载、地区资格和服务异常。能力位与真实服务必须分开。

## 关键实现与统一决策

| 范围 | 实际源码 | 发现 / Elyra 决策 |
| --- | --- | --- |
| MG 表单及隐藏项 | A `GestaltView.swift`, `GestaltStore.swift`, `CustomKeyView.swift` | `mgOverrideGates`, `showRegionTweak`, `showCustomKeys`, `mgCustKeyArray`, atomic/alternate write, autoRespring、硬件伪装及 iPadOS identity 均计入矩阵，不仅统计可见 Toggle。 |
| MG 原值 | A `mgKeyBinding` | 关闭常通过删除字段完成，不等于恢复真实原值；Elyra 保留完整原始字节和类型，恢复不猜值。 |
| 设备门控 | A `GestaltView.swift` | Boot Chime/Charge Limit 的条件相互用了另一能力检测。Elyra 不移植这些型号隐藏规则。 |
| 写入实现 | A `WriteHelpers.swift` | `writeFile(data,to:)` 实际写死 MG URL，忽略传入目标；`writeFileAtomically` 是 inode 内 truncate/write/fsync，不是原子 rename，失败恢复不完全验证。不能直接复用为通用安全写入器。 |
| 状态共享 | A `KeypadManager.swift`, 全局 `kp` | 同时有全局实例和 `shared`；Elyra 使用单个应用级 actor，UI 状态属于窗口。 |
| 二进制修改 | A `mgSetiPadOS` | 在 CacheData hex 固定片段用正则猜偏移，存在无法泛化的布局风险；不迁移该算法。 |
| MG 事务 | B `GestaltManager.swift`, `GestaltDocument.swift` | snapshot freshness、备份完整性、原值缺失记录、差异与类型对比、恢复失败明确报错较完善。Elyra 采用其事务思想，自行实现本地 actor；未复制设备写入后端。 |
| 设备归属 | B `DevicePlistIdentity.swift`, `DeviceBoundPlist.swift` | 同设备 unique IDs、Keychain HMAC 与模型/地区分开；hash 不是身份。Elyra 导入文件不产生设备归属证明。 |
| CacheData | B `MobileGestaltCacheLayout.swift`, `DeviceCacheOptions.swift`, `GXMobileGestaltImage.m` | 设备 Mach-O 描述符匹配 UUID/count/index/type，拒绝不明确布局；与 A 偏移猜测有实质区别。仍需设备侧验证；当前不修改二进制系统缓存。 |
| DI | A `GestaltStore`, `GestaltView`; B `Capabilities`, `ContentView`, manager artwork logic | 可见能力位与 artwork subtype，未发现独立媒体几何参数。B 关闭 DI 仅恢复共享 Artwork dictionary 的 subtype 成员，避免覆盖设备名。 |
| 壁纸 | A `PBHandler`, `PosterBoardView`; B `CustomizationFiles/Themes/Store` | 三种 provider 目录、标识重生成；B 增加归档路径/链接/CRC/数量/解压大小限制与安装 hash/回滚。Elyra 已实现有界归档校验及条目预览；系统安装尚未实现。 |
| 拨号盘 | A `KeypadManager`, `KeypadView` | 12 键、6 种 cache 文件名变体、明暗、图片尺寸、圆形裁剪、主题归档识别；不能把图片库冒充真实拨号盘替换。 |
| 启动图 | B `LaunchArtwork*`, `GXLaunchServices*` | 原生应用枚举与容器身份、PNG 转换、inode 级原值、受控回滚和照片导出；需要跨容器权限，不是普通 sandbox 功能。 |
| 通知音 | B `AppSound*`, `NotificationSound*`, `CapturedSoundStore` | AVFoundation 转码、捕获路径、按 app 管理原值；替换需要其他应用容器写入，不能将本地音频预览称为替换成功。 |
| 配对 | B `DeviceConnection*`, `DeviceConsole*`, `DevicePairingStore`, `Native/DeviceConsole` | Rust RPPairing/RSD/Lockdown/syslog_relay；私密 PIN 不记日志、generation-scoped cancellation、路径迁移与 LocalDevVPN 依赖。合法配对模块不应混同文件逃逸，但尚需独立迁移/构建与隐私审查。 |
| 配置资料 | A `ConfigView`; B `SystemSettingsStore` | A 混合锁屏 footnote 与监督/组织信息。Elyra 不执行未经授权的管理配置修改，也不以普通外观设置包装它。 |
| 文件 | A `FileBrowserView`, `FileHelpers`, `PlistManager`, `TextViewer`, `OperationsView` | 普通浏览编辑与 escape/grant 混合；Elyra 仅对授权导入及受管理副本操作，尚未移植完整目录浏览与文本编辑。 |
| Respring | A `Respring`; B `NeoSpringView` | 资源耗尽 WebKit 方法，不是受支持 API；本构建不运行。 |
| 扩展 | B `ShareExtension`, `Shared*`; A 无独立扩展目标 | 共同签名 App Group、持久 inbox、文件大小、验证、取消；Elyra 尚未迁移，不声称 fileImporter 等同分享扩展。 |
| 持久化 | A AppStorage/UserDefaults + 文件；B actor 文件、Keychain、App Group | Elyra 文件 JSON/plist + actor，共享数据与窗口草稿分开；已有 index 损坏不静默重置。 |
| CI | A `ipabuild.sh`; B `.github/workflows/build.yml`, `.github/scripts/build-ipa.sh` | B 原 workflow 使用 `xcode-27` runner 标签，不能假定目标仓库拥有该 runner。Elyra 使用标准 macOS runner、实际已安装 stable Xcode、设备 archive 与结构验证。无 Xcode 27 SDK 就不声明 27 SDK 测试通过。 |

## 原生及第三方依赖

A：Swift/SwiftUI、Objective-C `worse_query.m`/`pathleak.m`、Security、底层文件 API、系统 libarchive 封装、WebKit。App Group `group.com.jbdotparty.Erosion.WQ`。

B：Swift/SwiftUI、Objective-C entitlement reader、device identity、cache/image reader、LaunchServices parser/discovery、customization access、`worse_query`；ZIPFoundation 0.9.20 @ `22787ffb59de99e5dc1fbfe80b19c97a904ad48d`（MIT）；Rust native console，vendored idevice @ `7bd551c16c6dd2e058740d85a2d9399a51a776e9`（MIT），AirCard 连接代码（MIT），aws-lc/C toolchain、cmake/nasm（依目标）；App Group `group.com.huami.gestultx`。NeoSpring GPL 参考实现、Gester MIT、Primer Octicons MIT。完整上游许可副本保留在 Resources/Licenses。

Elyra 0.1 仅编译 Swift/SwiftUI 及 Apple frameworks；0.2 新增实际编译的 ZIPFoundation 0.9.20 固定 revision，用于有界离线检查。仍无原生 escape、Rust 库、特殊 entitlement 或分享扩展。改编的 `Capability.swift` 保留 huamidev GPL-3.0-only 版权告知。未把其他许可证推断为 MIT。完整对应源码随本项目提供。

## 主要阻碍与残余风险

1. 无授权、可验证的系统 writer；签名本身不会授予任意系统缓存访问。不能把上游 escape 移入后就称安全通用支持。
2. 本地仍无 Xcode/真机；远程基线现已通过 Xcode 分析、模拟器测试和设备归档。最新 0.2 结果见 TEST_REPORT。
4. SHA-256 仅检查备份完整性，不防同权限攻击者同时改 payload 与 metadata；不提供设备身份认证。
5. 单 actor 保证本进程多窗口一致性；不保证第二进程或外部文件修改与提交之间的跨进程锁。尚无 app extension，故当前无该写入场景。
6. 本地提交有 journal、原子替换和失败回读；没有文件系统级断电 fsync 验收。导入/素材入库和回收站并非完整 journal 事务，极端中断可留下孤立文件，需后续修复工具。
7. 此报告是可复核的首轮深入功能审计，不等于所有源代码与 vendored 依赖已通过全面安全认证。
