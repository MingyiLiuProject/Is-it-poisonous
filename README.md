# 有毒吗？ · Is It Poisonous?

一款帮助宠物主人快速查询常见植物潜在毒性的原生 iOS 应用。

项目灵感来自 [Is It Toxic To?](https://iitt.chester.how/)，使用 SwiftUI 重新设计为适合手机使用的中文体验。当前仓库是可继续开发的 MVP，内置少量离线示例数据，用于验证产品流程与技术架构。

> 本应用仅用于初步风险筛查，不能替代兽医诊断。疑似误食时请立即联系当地兽医，不要等待症状出现。

## 当前需求

### 核心功能

- 按中文名、英文名、学名或常见别名搜索植物
- 按猫、狗、马筛选有毒植物
- 展示毒性对象、毒性成分和常见临床表现
- 收藏常用植物，并保存在设备本地
- 提供瑞士中毒急救与 ASPCA 联系入口
- 每条记录保留可追溯的资料来源
- 明确展示“未列出毒性不等于可以食用”

### 当前数据范围

- 内置 12 种常见植物作为 MVP 示例
- 数据在本地运行，无需注册或联网查询
- 示例资料最近核对日期：2026-07-15
- 当前数据不完整，不能作为完整毒物数据库使用

## 页面结构

1. **查询**：搜索、宠物筛选和植物列表
2. **植物详情**：毒性对象、成分、症状、来源与收藏
3. **收藏**：快速访问用户关注的植物
4. **应急与说明**：误食后的准备事项、求助入口和免责声明

## 技术栈

- Swift 5.9
- SwiftUI
- iOS 17+
- UserDefaults 本地收藏
- XCTest
- XcodeGen 项目配置

项目主要目录：

```text
YouDuMa/
├── App/          # 应用入口
├── Data/         # 离线植物数据
├── Design/       # 颜色与视觉规范
├── Models/       # 数据模型
├── Stores/       # 收藏状态
├── Views/        # SwiftUI 页面与组件
└── Resources/    # Assets
```

## 在 Mac 上运行

需要安装 Xcode 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```bash
brew install xcodegen
git clone https://github.com/MingyiLiuProject/Is-it-poisonous.git
cd Is-it-poisonous
xcodegen generate
open YouDuMa.xcodeproj
```

在 Xcode 中选择 iPhone 模拟器并运行。首次真机运行时，需要在 **Signing & Capabilities** 中选择自己的开发团队。

## 数据与安全

示例数据主要参考：

- [ASPCA Toxic and Non-Toxic Plants](https://www.aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants)
- [ASPCA Animal Poison Control](https://www.aspca.org/pet-care/aspca-poison-control)
- [Tox Info Suisse](https://www.toxinfo.ch/)

正式发布前需要：

- 获得可用于产品发布的数据授权
- 由兽医或动物毒理学专业人员审核内容
- 为每条记录保存来源、更新时间和版本历史
- 根据用户所在国家或地区显示正确的紧急联系方式
- 建立数据纠错和定期更新流程

请勿直接复制参考网站的完整数据集，也不要热链第三方植物图片。

## 下一阶段

- 扩充经过授权和专业审核的植物数据库
- 增加德语、英语和繁体中文本地化
- 支持按毒性状态和植物类别筛选
- 增加用户所在地区的急诊兽医入口
- 研究端侧植物图片识别，并明确显示识别置信度
- 补充 App 图标、截图、无障碍检查和 UI 测试

## English summary

**Is It Poisonous?** is a SwiftUI iOS prototype for searching common plants that may be toxic to cats, dogs, or horses. It includes offline sample data, pet filters, plant details, favorites, emergency guidance, and source attribution. The bundled data is intentionally limited and must not be used as a substitute for professional veterinary advice.
