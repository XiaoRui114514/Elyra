# 功能命名与本地化

Elyra 使用常见系统功能名称，不另造营销名称。优先参考 Apple 官方简体中文文档，并核对两个基础仓库的实际功能词条。界面入口使用“灵动岛”“设备能力”“文件管理”“备份与恢复”；内部类型与研究文档可保留 Dynamic Island Lab，产品页面不使用双语拼接的“实验室”标题。

| English | 简体中文 | 依据与范围 |
| --- | --- | --- |
| Dynamic Island | 灵动岛 | Apple 官方用语；上游同名能力标记 |
| Always-On Display | 全天候显示 | Apple 官方用语；能力标记不代表面板支持 |
| Stage Manager | 台前调度 | Apple 官方用语；两类设备同一入口 |
| Camera Control | 相机控制 | Apple 官方用语；不声称增加实体部件 |
| Action Button | 操作按钮 | Apple 官方用语 |
| Charge Limit | 充电上限 | 与 GestaltX 功能名称一致 |
| AOD Vibrancy | 全天候显示鲜明度 | 技术选项，不伪造 Apple 正式产品名 |
| Device capabilities | 设备能力 | 区分配置声明与真实功能 |
| MobileGestalt / ArtworkDeviceSubType / PWM / HDR | 保留技术名称 | 原始键与品牌名不擅自翻译 |

依据：[Apple 灵动岛](https://support.apple.com/zh-cn/guide/iphone/iph28f50d10d/ios)、[全天候显示屏](https://support.apple.com/zh-cn/guide/iphone/iph7117338a8/ios)、[台前调度](https://support.apple.com/zh-cn/105075)、[相机控制与操作按钮](https://support.apple.com/zh-cn/105103)、[GestaltX 实际词条](https://github.com/huamidev/GestaltX/blob/d1d5473734440e8f2e797494ac373427c02fd674/GestaltX/Localizable.xcstrings) 与 [Erosion 实际实现](https://github.com/jailbreakdotparty/Erosion/tree/12c0a2d00c444c9b09112608b47d4d6c10e0df14/Erosion)。来源与许可证继续保留在 THIRD_PARTY_NOTICES。


## 语言设置

设置 → 语言：跟随系统 / 简体中文 / English。默认跟随系统，在首选语言中选择首个支持项，无匹配时回退英文。中文变体使用现有简体中文资源，不宣称提供繁体翻译。

共享 LocalizationStore 保存选择并同步全部窗口；SwiftUI locale 与动态词条查询使用同一语言。切换不重建窗口根视图，不修改 AppleLanguages 或系统语言，不清空导航或草稿。日期、文件大小、功能名称、状态、操作说明及 Elyra 自定义错误按选择显示。文件名、配置键和值保持原样。原生文件选择器、Quick Look 和系统产生的错误可能仍遵循系统自身语言；许可证原文和已记录的原始诊断细节保留。

523 个中英文词条，回退报告见 audit/localization-fallbacks.json。生成脚本会拒绝未补齐翻译的固定词条，包括操作名称及备份来源。iPhone/iPad 模拟器已验证即时切换、跟随系统、重启保留、首页组件与灵动岛标题同步；完整证据见 TEST_REPORT。VoiceOver 真机听读、多窗口同时切换和全部系统弹窗尚未人工验收。
