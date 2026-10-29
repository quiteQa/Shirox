# Shirox Bangumi

基于 [xibrox/Shirox](https://github.com/xibrox/Shirox) 的动画资料库 App，内置 **Bangumi 动画元数据**。安装后，在模块页或首页来源菜单直接选择 **Bangumi**，无需导入模块 URL 或下载脚本。

当前发行版：**1.0.7（126）** · [发行说明](RELEASE_NOTES.md) · [全部发行版](https://github.com/quiteQa/Shirox/releases) · [构建记录](https://github.com/quiteQa/Shirox/actions/workflows/nightly.yaml)

## 下载发行版

以下文件使用 **Release** 配置构建，包含 Bangumi 配置与脚本。

| 平台 | 安装包 | 系统要求 |
| --- | --- | --- |
| iPhone / iPad | [Shirox.ipa](https://github.com/quiteQa/Shirox/releases/download/v1.0.7-bangumi.1/Shirox.ipa) | iOS / iPadOS 15+ |
| Mac 原生版 | [Shirox-macOS.dmg](https://github.com/quiteQa/Shirox/releases/download/v1.0.7-bangumi.1/Shirox-macOS.dmg) | macOS 14+ |
| Mac Catalyst 版 | [Shirox-Catalyst.dmg](https://github.com/quiteQa/Shirox/releases/download/v1.0.7-bangumi.1/Shirox-Catalyst.dmg) | macOS 14+ |
| Apple TV | [Shirox-tvos.ipa](https://github.com/quiteQa/Shirox/releases/download/v1.0.7-bangumi.1/Shirox-tvos.ipa) | tvOS 18.6+ |

[最新发行页](https://github.com/quiteQa/Shirox/releases/latest) · [SHA-256 校验文件](https://github.com/quiteQa/Shirox/releases/download/v1.0.7-bangumi.1/SHA256SUMS.txt) · [iOS 调试符号](https://github.com/quiteQa/Shirox/releases/download/v1.0.7-bangumi.1/Shirox-iOS-dSYMs.zip)

**iOS / tvOS：** IPA 未签名，需要使用自己的签名方式侧载。**Mac：** 打开 DMG，将 App 拖入“应用程序”；两个 Mac 版本均使用临时签名，未经过 Apple 公证。首次打开若被拦截，可在系统设置的“隐私与安全性”中处理。

### 侧载源

[一键添加侧载源](https://altdirect.app/?url=https://raw.githubusercontent.com/quiteQa/Shirox/main/apps.json)，或在支持的侧载工具中添加：

```text
https://raw.githubusercontent.com/quiteQa/Shirox/main/apps.json
```

这是此 Fork 的 App 安装源，直接下载本仓库发行版。它与外部模块 JSON 的用途不同；内置 Bangumi 不需要再导入任何模块链接。

## 使用 Bangumi

1. 安装此仓库的发行版。
2. 打开 **设置 → 模块**，或首页的来源菜单。
3. 选择 **Bangumi · 内置动画元数据**。

首页提供评分排行和最新首播；搜索、动画详情和剧集信息读取 Bangumi 数据。可查看中文与原文标题、别名、封面、简介、评分、首播日期、标签、制作公司和导演。公开数据无需 Bangumi 账号，条目和封面仍需联网。

旧 Bangumi 来源选择和收藏条目保持兼容，导入副本不会重复显示。脚本随 App 更新，刷新外部模块不会替换内置代码。

Bangumi 提供元数据。播放时，在详情页选择另行安装的播放模块并确认对应条目。元数据来源不会进入播放和下载源列表，也不会进行串流检查。本版本没有 Bangumi 账号登录或自动追番同步。

## 原有能力

- AniList / MyAnimeList 资料库与追踪、本机资料库和收藏。
- JavaScript 播放及漫画模块、Jellyfin、本地视频文件。
- 视频播放、字幕、画中画、AirPlay 与 Chromecast。
- 动画和漫画下载、离线播放与阅读。
- iPhone、iPad、Mac 和 Apple TV 的原生界面，支持简体中文等 13 种语言。

各服务仍有自己的账号与功能要求。更详细的元数据协议与迁移说明见 [docs/BANGUMI.md](docs/BANGUMI.md)；独立脚本维护在 [quiteQa/shirox-bangumi](https://github.com/quiteQa/shirox-bangumi)。

## 从源码构建

需要 macOS、Xcode 26 和命令行工具。依赖由 Swift Package Manager 解析；生成 Mac DMG 需要 `create-dmg`，脚本会通过 Homebrew 安装。

```bash
git clone https://github.com/quiteQa/Shirox.git
cd Shirox
open Shirox.xcodeproj
```

发行构建脚本：

```bash
bash buildipa.sh       # build/Shirox.ipa
bash builddmg.sh       # build/Shirox-macOS.dmg
bash buildcatalyst.sh  # build/Shirox-Catalyst.dmg
bash buildtvos.sh      # build/Shirox-tvos.ipa
```

需要自己的签名设置时，从 `Configurations/Shirox.local.xcconfig.template` 创建本地配置。四个 scheme 为 `Shirox_iOS`、`Shirox_macOS`、`Shirox_MacCatalyst` 和 `Shirox_tvOS`。

### 自动发行

[Release Shirox Bangumi](https://github.com/quiteQa/Shirox/actions/workflows/nightly.yaml) 工作流支持手动运行。准备新版本时，更新 `Configurations/Release.json`、工程中的版本与构建号、`apps.json` 及 `RELEASE_NOTES.md`，再推送到 `main`。

CI 检查版本、本地化和图标，使用 Release 配置构建四个平台，从生成的 IPA / DMG 中检查版本、更新地址和内置 Bangumi 资源，并验证 Mac 签名。全部通过后发布 GitHub Release、校验文件与 iOS 调试符号，并将实际 IPA 大小写回侧载源。

原生 XCTest 尚未执行，尚未真机验证。此前内置版的脚本测试与原生编译记录见 [验证说明](docs/BANGUMI.md)。

## 来源与许可证

原项目由 [xibrox](https://github.com/xibrox) 开发，本分支由 [quiteQa](https://github.com/quiteQa) 维护 Bangumi 集成与发行。上游：[xibrox/Shirox](https://github.com/xibrox/Shirox) · [上游社区](https://discord.com/invite/b9tZSuJj73) · [支持原作者](https://ko-fi.com/xibrox)。

遵循 [PolyForm Noncommercial License 1.0.0](LICENSE)，允许非商业用途的使用、修改和分享。动画元数据来自 [Bangumi](https://bgm.tv)；App 不托管视频内容。
