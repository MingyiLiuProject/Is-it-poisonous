# 有毒吗？ · Is It Poisonous?

一款帮助宠物主人快速查询常见植物潜在毒性的原生 iOS 应用。

项目灵感来自 [Is It Toxic To?](https://iitt.chester.how/)，使用 SwiftUI 重新设计为适合手机使用的中文体验。当前仓库包含可离线查询的 ASPCA 猫、狗、马植物目录。

> 本应用仅用于初步风险筛查，不能替代兽医诊断。疑似误食时请立即联系当地兽医，不要等待症状出现。

## 当前需求

### 核心功能

- 按中文俗名、中文别名、英文俗名、专业学名搜索植物
- 支持完整拼音、无空格拼音、拼音首字母和轻微拼写错误的模糊搜索
- 为全部植物显示 Wikimedia Commons 开放许可照片
- 图片按需联网加载并使用内存/磁盘缓存，详情页显示作者、许可和原始页面
- 按猫、狗、马筛选有毒植物
- 展示毒性对象、毒性成分和常见临床表现
- 收藏常用植物，并保存在设备本地
- 提供宠物接触植物后的可勾选行动清单、危险信号与就医准备信息
- 每条记录保留可追溯的资料来源
- 明确展示“未列出毒性不等于可以食用”

### 当前数据范围

- 数据库 v3 合并 ASPCA 猫、狗、马的有毒与无毒植物列表，共 1023 条记录
- 全部记录包含中文俗名、专业学名和拼音搜索词
- 全部 1023 条记录已匹配 JPEG 植物照片；低置信度图片会明确标记“图片待复核”
- 中文名称优先使用人工映射、Wikidata 与 GBIF；无法可靠匹配的名称使用自动翻译并标记“待专业复核”
- 12 种常见植物包含经过人工整理的毒性成分与临床表现
- 名称与毒性数据可离线查询，无需注册；植物照片首次查看时需要联网
- 数据最近核对日期：2026-07-16
- 临床描述仍不完整，不能作为完整毒物医学数据库使用

## 页面结构

1. **查询**：搜索、宠物筛选和植物列表
2. **植物详情**：毒性对象、成分、症状、来源与收藏
3. **收藏**：快速访问用户关注的植物
4. **接触后行动**：可勾选行动项、危险信号、就医准备和免责声明

## 技术栈

- Swift 5.9
- SwiftUI
- iOS 17+
- UserDefaults 本地收藏
- XCTest
- XcodeGen 项目配置
- 自适应浅色/深色主题、Dynamic Type 与减少动态效果支持
- 基于弹簧的即时按压反馈、系统材质层与适度触觉反馈

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

### 重建数据库

安装数据工具依赖并运行：

```bash
python -m pip install -r tools/data_requirements.txt
python tools/import_aspca_plants.py
python tools/enrich_plant_names.py
python tools/enrich_plant_images.py
```

第一步解析猫、狗、马列表，合并相同 ASPCA 详情页的状态；第二步通过专业学名匹配 [Wikidata](https://www.wikidata.org/) 与 [GBIF](https://www.gbif.org/) 的中文名，并生成简体中文、别名和拼音索引；第三步通过 Wikidata 分类图片和 Wikimedia Commons 搜索匹配开放许可 JPEG 照片。

图片脚本只接受 CC0、公共领域、CC BY 和 CC BY-SA 许可，并保存作者、许可链接及 Commons 原始页面。App 不复制 ASPCA 图片；图片通过 Wikimedia 的 500px 标准缩略图地址按需加载。

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

## 在 Windows 浏览器查看原生 App

仓库内置 GitHub Actions 工作流，可以在 GitHub 的 macOS 环境中编译 iOS Simulator App，再交给 Appetize 在浏览器中运行。

### 1. 云端编译

1. 打开仓库的 [Actions 页面](https://github.com/MingyiLiuProject/Is-it-poisonous/actions/workflows/ios-browser-preview.yml)
2. 选择 **Build iOS Browser Preview**
3. 点击 **Run workflow**
4. 等待 `Build simulator app` 完成
5. 在运行结果底部下载 `YouDuMa-iOS-Simulator` artifact

下载的 artifact 是 GitHub 生成的外层压缩包。解压一次后，会得到真正需要上传的 `YouDuMa-simulator.zip`；不要再次解压这个内层文件。

### 2. 在浏览器运行

1. 打开 [Appetize Upload](https://appetize.io/upload)
2. 上传 `YouDuMa-simulator.zip`
3. 平台选择 iOS
4. 等待处理完成后打开 Appetize 提供的预览链接

Appetize 是第三方云服务，免费额度、保存期限和公开分享能力以其当前套餐为准。此构建仅用于 iOS Simulator，不能直接安装到实体 iPhone。

## 数据与安全

数据主要参考：

- [ASPCA Toxic and Non-Toxic Plants](https://www.aspca.org/pet-care/aspca-poison-control/toxic-and-non-toxic-plants)
- [ASPCA Animal Poison Control](https://www.aspca.org/pet-care/aspca-poison-control)
- [Wikidata](https://www.wikidata.org/)
- [GBIF](https://www.gbif.org/)
- [Wikimedia Commons](https://commons.wikimedia.org/)
- [Cornell University College of Veterinary Medicine](https://www.vet.cornell.edu/departments-centers-and-institutes/riney-canine-health-center/canine-health-information/first-aid-poisonous-substances)
- [RSPCA Pet First Aid](https://www.rspca.org.uk/adviceandwelfare/pets/dogs/health/firstaid)

正式发布前需要：

- 获得可用于产品发布的数据授权
- 由兽医或动物毒理学专业人员审核内容
- 为每条记录保存来源、更新时间和版本历史
- 为不同地区提供经过专业审核的行动说明与就医路径
- 建立数据纠错和定期更新流程

请勿直接复制参考网站的完整数据集，也不要热链第三方植物图片。

## 下一阶段

- 扩充经过授权和专业审核的植物数据库
- 增加德语、英语和繁体中文本地化
- 支持按毒性状态和植物类别筛选
- 优化行动清单、危险信号和附近兽医院地图入口
- 研究端侧植物图片识别，并明确显示识别置信度
- 补充 App 图标、截图、无障碍检查和 UI 测试

## English summary

**Is It Poisonous?** is a SwiftUI iOS prototype for searching plants that may be toxic to cats, dogs, or horses. Its catalog supports Chinese, English, scientific-name, pinyin, initials, and typo-tolerant search. Openly licensed Wikimedia Commons photos are loaded on demand with attribution and caching. It must not be used as a substitute for professional veterinary advice.
