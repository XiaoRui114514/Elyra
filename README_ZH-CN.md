# Elyra

面向 iPhone 和 iPad 的 SwiftUI 配置与文件工具箱，根据当前窗口尺寸调整导航和内容布局。

[功能矩阵](docs/FEATURE_MATRIX.md) · [构建与测试](docs/TEST_REPORT.md) · [构建说明](docs/BUILDING.md) · [已知问题](docs/KNOWN_ISSUES.md)

0.3 新增设备端 MobileGestalt 访问及能力字段写入，接入已固定版本的上游原生模块。直接访问不可用时，需要签名配置提供有效 App Group；26、27 系统均以实际读写权限检测为准，不承诺每个构建都可用。外部导入文件仍是独立本地文档。编译、签名与真机测试状态分别记录在测试报告中。

[下载 0.3.0（18）未签名 IPA](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024/artifacts/14122258455) · [已通过的 CI](https://github.com/XiaoRui114514/Elyra/actions/runs/43617128024)。开发版 IPA 需要签名，尚未完成真机安装与系统效果测试。

- 浏览和编辑 8 类 plist 数据，搜索嵌套字段，暂存修改并预览差异。
- 保存前校验备份，按原始字节恢复，检测多窗口版本冲突。
- 读取设备缓存，暂存能力与外观字段，确认写入、回读验证，并恢复设备绑定备份。身份及二进制缓存字段受保护。
- 检查灵动岛配置；系统胶囊圆角仍无经过验证的调整参数。
- 分别记录空闲、录屏、计时、通话、媒体及多活动状态下的形状与圆角。
- 预览和导出文件；编辑 UTF-8 文本，保留文件版本备份。
- 检查 ZIP 与 `.tendies` 归档，验证路径、CRC 和解压大小限制。
- 在“设置 → 语言”选择简体中文、English 或跟随系统。
- 重新设计系统概览，提供手动实验性注销按钮；关于页直接显示三个账号卡片，使用官方应用图标及品牌配色。

功能名称沿用 Apple 官方用语及参考项目的通用叫法。参见[命名与本地化](docs/NAMING_AND_LOCALIZATION.md)、[灵动岛研究](docs/DYNAMIC_ISLAND_RESEARCH.md)。

[GitHub Actions](https://github.com/XiaoRui114514/Elyra/actions/workflows/build.yml) 执行核心测试、Xcode 分析及 iPhone/iPad 界面测试，归档真实 arm64 设备应用并校验 IPA。产物未签名，需要合法签名与描述文件；准确测试提交、下载入口和安装状态见[测试报告](docs/TEST_REPORT.md)。

开发时打开 `Elyra.xcodeproj`，核心模块可通过 `swift test` 测试。采用 GPL-3.0-only，版权和依赖声明见 [LICENSE](LICENSE) 与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
