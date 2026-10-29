# Shirox Bangumi 1.0.7 (126)

Bangumi 已作为动画元数据来源内置到 App。安装后在模块页或首页来源菜单直接选择 **Bangumi**，无需导入模块 URL 或下载脚本。公开元数据无需 Bangumi 账号，读取条目和封面仍需联网。

- 首页提供评分排行和最新首播，搜索、动画详情和剧集信息读取 Bangumi 数据。
- 展示标题、别名、封面、简介、评分、日期、标签、制作公司和导演。
- 元数据来源不再进行串流检查，也不会出现在播放和下载源列表。
- 兼容旧 Bangumi 来源选择和已收藏条目；详情页可另选安装的播放模块。
- 本次使用 Release 配置构建，版本为 1.0.7，构建号为 126。

下载：`Shirox.ipa`（iPhone/iPad）、`Shirox-tvos.ipa`（Apple TV）、`Shirox-macOS.dmg`（原生 Mac）、`Shirox-Catalyst.dmg`（Mac Catalyst）。`SHA256SUMS.txt` 提供文件校验值，`Shirox-iOS-dSYMs.zip` 用于 iOS 崩溃符号化。

iOS 和 tvOS 安装包未签名，需要自行签名侧载。两个 Mac 包使用临时签名，未经过 Apple 公证。尚未真机验证，也未执行原生 XCTest。

基于 [xibrox/Shirox](https://github.com/xibrox/Shirox)，遵循仓库的 PolyForm Noncommercial 1.0.0 许可证。
