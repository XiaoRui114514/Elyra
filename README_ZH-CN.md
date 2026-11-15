# Elyra

面向 iPhone 和 iPad 的 SwiftUI 配置与文件工具箱，根据当前窗口尺寸调整导航和内容布局。

[功能矩阵](docs/FEATURE_MATRIX.md) · [测试报告](docs/TEST_REPORT.md) · [构建说明](docs/BUILDING.md) · [已知问题](docs/KNOWN_ISSUES.md)

[下载 0.4.1 重签版 IPA](https://github.com/XiaoRui114514/Elyra/releases/download/v0.4.1-dev/Elyra-resignable.ipa) · [开发版发布页](https://github.com/XiaoRui114514/Elyra/releases/tag/v0.4.1-dev)

重签版和未签名版均需合法签名与描述文件。重签版以 ad-hoc 签名嵌入 App Group 配置，方便签名工具识别所需配置；这本身不授予系统权限。尚未完成真机安装与系统效果测试，准确提交、校验值和模拟器结果见[测试报告](docs/TEST_REPORT.md)。

- **智能功能**：一键合并七项智能标记和地区代码，保留销售地区与设备专有 Siri 配置，统一预览并确认。
- **型号名称**：同步三个显示字段，支持按设备记录恢复；功能卡片显示开启、关闭状态及勾选标记。
- **系统配置**：自动检测 MobileGestalt 访问权限；分类和功能使用自适应卡片，提供明确的“修改”按钮、变更预览、设备备份、回读校验和记录值恢复。是否可写以最终签名、可用容器及实际权限检测为准。
- **配置方案**：保存、导入和导出功能选择，检测冲突，一次预览并确认多个功能的变更。
- **文档与文件**：编辑 8 类 plist 数据，搜索嵌套字段，暂存草稿；预览和导出素材，编辑带版本备份的 UTF-8 文本，检查 ZIP 与 `.tendies` 的路径、CRC 和大小限制。
- **备份中心**：离线查看和导出经过校验的设备备份，比较当前配置，单独确认恢复操作。外部导入文件不会被当作可信设备原值。
- **窗口与显示**：查看当前窗口尺寸、安全区域、显示缩放、像素尺寸、刷新能力及 EDR 余量；可测量应用回调频率。
- **灵动岛**：归入“显示”，提供配置检查、记录字段恢复、外观观察与明确标注的应用内预览。尚无经过验证的系统圆角或布局修复。
- **界面**：各分区独立保留导航，使用原生控件；支持简体中文、English 和跟随系统，首页提供手动实验性注销按钮，关于页直接展示账号卡片。

iPhone 和 iPad 使用同一套功能与配置引擎。能力标记和硬件、Apple 服务是否可用分别处理。系统素材安装、完整目录浏览和配对仍在迁移，进度见[功能矩阵](docs/FEATURE_MATRIX.md)。

[GitHub Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml) 执行核心与 Python 检查、Xcode 分析及每类设备 9 项界面测试，生成并校验两种真实 arm64 IPA。Stage Manager 连续缩放、外接显示器、VoiceOver 和 iOS/iPadOS 27 运行验证仍待完成。

开发时打开 `Elyra.xcodeproj`，核心模块可通过 `swift test` 测试。采用 GPL-3.0-only，必要的版权与依赖声明保留在 [LICENSE](LICENSE) 和 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。[源码审查](docs/REVIEW_0.4.md) · [灵动岛研究](docs/DYNAMIC_ISLAND_RESEARCH.md)
