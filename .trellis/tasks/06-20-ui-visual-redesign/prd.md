# UI 视觉重做

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根 `ROADMAP.md` + `DECISIONS.md`，及本 prd 列出的所有锁定决策。**
**前置：M0/M1/M2/M3 + auto-discover-vault + clipboard-system-notification + tray-lifecycle 已完成。**
**🚨 本任务为实现型任务，不是规划型——必须按 checklist 写代码 + widget test + 实跑后才能 finish-work，不可只更新文档归档。**

---

## 背景：为什么做这个

Roosty 当前用 Flutter 默认 Material 模板（`ColorScheme.fromSeed(seedColor: #2F6F63)`），整个产品看起来像「未完成的脚手架」而非有设计感的开源工具。这是 UX overhaul 父任务的最后一块拼图：把 Roosty 从「能用」推到「想用」。

视觉调性已通过 brainstorm 锁定为「**温暖手作（知识库友好）**」—— 贴合 Obsidian 生态调性、贴合「叼线索回家」的产品语义、与同类工具（Cubox/Hoarder/Raycast 全冷调极简）形成视觉差异化。

## 目标

把 Roosty 全产品 UI 升级到「温暖手作」调性，亮+暗双主题，从主窗口、首启卡片、设置页、归巢历史、mini 卡片，到托盘 tooltip、错误提示，全部按统一 token 系统重做。

## 完成标准（端到端实跑，必须真验证）

1. 启动 Roosty → 主窗口看起来「不像 Material 模板」，能一眼看出是温暖纸质感
2. 切换系统主题（Windows 设置 → 个性化 → 颜色 → 选浅色/深色）→ Roosty 跟随切换，亮暗两套都好看
3. 首启卡片（vault 自动发现）使用新视觉
4. 复制 URL → mini 卡片使用新视觉（不再是默认白底圆角）
5. 设置页所有元素（开关、按钮、列表项、对话框、退出按钮）使用新视觉
6. 字体：标题/品牌处是思源宋体 + 英文 Lora，正文中文也是思源宋体（全打包）
7. 主色：所有交互元素（按钮、focus、链接、tag）用 #B07C4E（暗色 #D89968）
8. 动效：所有过渡 150-200ms，无 Material 水波纹
9. APK / Windows 安装包构建成功，包体增加 5-8 MB（思源宋体子集化后的代价）

---

## 锁定决策（已与用户敲定，不可改）

### 1. 调性：温暖手作（知识库友好）
- 米色暖底（不纯白）
- 圆角 12-16px（不是 Material 的 4px）
- 衬线 / 半衬线字体优先
- 卡片轻投影 + 1px 暖灰描边
- 不用 Material elevation，改成扁 + 暖

### 2. 配色 token

**亮色主题：**
| 角色 | 色值 | 用途 |
|------|------|------|
| `bgBase` | `#FAF7F2` | 整体背景（米白） |
| `bgCard` | `#FFFFFF` | 卡片浮起底（纯白） |
| `bgElevated` | `#F2EBDF` | 二级面板（设置项分组等） |
| `textPrimary` | `#3A2E22` | 主文本（深棕） |
| `textSecondary` | `#7A6B5C` | 次要文本（灰棕） |
| `textDisabled` | `#B5A99A` | 禁用文本 |
| **`primary`** | **`#B07C4E`** | 主色（暑褐） |
| `primaryHover` | `#9D6C42` | 主色 hover |
| `primarySubtle` | `#F4E8D9` | 主色淡背景（tag 底等） |
| `divider` | `#E8DECF` | 分隔/描边 |
| `error` | `#B45848` | 错误色 |
| `success` | `#5B7A6A` | 成功色（深杯茶绿） |

**暗色主题：**
| 角色 | 色值 |
|------|------|
| `bgBase` | `#1F1B17`（深棕黑，不是纯黑） |
| `bgCard` | `#2A2520`（比背景略亮） |
| `bgElevated` | `#332D27` |
| `textPrimary` | `#EDE5D8`（米色文字，不是纯白） |
| `textSecondary` | `#9C8E7E` |
| `textDisabled` | `#6B5F52` |
| **`primary`** | **`#D89968`** | 主色提亮一档保证 AA 对比度 |
| `primaryHover` | `#E5A878` |
| `primarySubtle` | `#3D2F22` |
| `divider` | `#3A332C` |
| `error` | `#D87A6A` |
| `success` | `#7A9483` |

### 3. 字体方案

**全打包，跨平台一致：**

| 字体 | 用途 | 来源 |
|------|------|------|
| **思源宋体（Source Han Serif SC）** | 中文主字体（标题 + 正文 + 品牌） | Google Fonts / Adobe 开源,SIL OFL 许可 |
| **Lora** | 英文标题 + 品牌处 | Google Fonts,SIL OFL 许可 |
| 系统等宽字体 fallback | URL / 代码 / 技术性内容 | 不打包,fontFamily: monospace |

**字号下限**：12px（小于 12 不允许使用，宋体在 Windows DirectWrite 下小字号会糊）。
**字重**：思源宋体 Regular(400) + SemiBold(600) 两档；Lora Regular(400) + Medium(500) 两档。
**子集化**：思源宋体仅保留中日韩常用字 + 标点 + 数字，体积约 5-7 MB（不打包全字符集 ~30MB）。

### 4. 圆角与间距 token

| Token | 值 | 用途 |
|------|-----|------|
| `radius-sm` | 6px | 小元素（标签 chip、tooltip） |
| `radius-md` | 12px | 按钮、输入框、二级卡片 |
| `radius-lg` | 16px | 主卡片、对话框、mini 卡片 |
| `radius-xl` | 24px | 大型空状态插画容器 |
| `space-1` | 4px | |
| `space-2` | 8px | |
| `space-3` | 12px | |
| `space-4` | 16px | |
| `space-6` | 24px | |
| `space-8` | 32px | |
| 内容容器最大宽 | 720px | 防长行难读 |

### 5. 阴影 token（克制）
- `shadow-sm`：`0 1px 2px rgba(58,46,34,0.06)` —— 卡片默认
- `shadow-md`：`0 4px 12px rgba(58,46,34,0.08)` —— 浮起卡片（mini 窗、对话框）
- `shadow-lg`：`0 12px 32px rgba(58,46,34,0.10)` —— hover 浮起
- 暗色版阴影用 `rgba(0,0,0,0.4)` 系列
- **禁用 Material 默认 elevation**

### 6. 动效原则
- 所有过渡 150-200ms，`Curves.easeOut`
- 点击 scale 0.98（持续 100ms 回弹）
- hover 投影从 `shadow-sm` 渐变到 `shadow-md`（150ms）
- 卡片入场：fade + slide-up 8px（200ms）
- mini 卡片消失：fade + slide-right 16px（200ms，同 prd 已锁定）
- **禁用 Material 默认 splash/highlight（水波纹）**，自定义为 `primarySubtle` 短 fade
- 不用 spring/物理动效

### 7. 暗色模式接入方式
- 跟随系统主题（`MaterialApp.themeMode: ThemeMode.system`）
- 设置页**暂不**提供手动切换（保持 MVP 简洁）
- 实时响应系统切换（用 `MediaQuery.platformBrightnessOf` + `WidgetsBindingObserver`）

### 8. Logo / 品牌
- 当前应该有占位 logo（饴麸鸟 / 鸟形图标）
- **本任务不重做 logo**——只是确保 logo 在新色板下能 work（如果不行，做最小调整：调棕色描边色调）
- 应用窗口标题保持 "Roosty"

---

## 节点 checklist

- [x] T1 创建 `lib/theme/` 目录（如不存在），分层：`tokens.dart`（color/spacing/radius/shadow） + `light_theme.dart` + `dark_theme.dart` + `text_theme.dart`
- [x] T2 字体打包：把思源宋体 + Lora 加进 `assets/fonts/`，子集化处理（用 `fonttools subset` 只保留 CJK 常用 + 标点 + 数字 + Latin），在 `pubspec.yaml` 注册
- [x] T3 Token 实现：所有色/间距/圆角/阴影写成 `ThemeExtension`，UI 层只引用 token 不写硬编码色值
- [x] T4 全工程审查：搜索所有 `Color(0x...)` `EdgeInsets.all(数字)` `BorderRadius.circular(数字)` `BoxShadow` `Colors.xxx`，逐一替换为 token 引用
- [x] T5 Material 默认覆盖：`themeData.splashFactory = NoSplash.splashFactory`，自定义 InkWell 行为为色块 fade
- [x] T6 Refactor 主入口 `RoostyApp`：去掉 `ColorScheme.fromSeed`，改为 `theme: lightTheme, darkTheme: darkTheme, themeMode: ThemeMode.system`
- [x] T7 逐组件视觉升级（按界面频率排序）：
  - [x] 主窗口 home_screen（顶栏、列表、设置项、按钮、对话框）
  - [x] 首启 vault 自动发现卡片
  - [x] mini 卡片（mini_card_window.dart） —— 新色板 + 圆角 16 + 衬线字
  - [x] 设置页（含「忽略列表」/「退出 Roosty」按钮）
  - [x] 归巢历史列表
  - [x] 退出确认对话框
  - [x] 错误/警告状态（vault 创建失败提示等）
  - [x] 空状态（无历史/无忽略列表项）
- [x] T8 暗色对比度验证：用 WCAG AA 标准 check（4.5:1 文本/3:1 大文本），不达标的提供调整 token 或文档说明
- [x] T9 widget test：① 主题切换（system light/dark）正确生效 ② 没有任何组件依赖 ColorScheme.fromSeed 的派生色（用 token 引用） ③ 关键组件（主按钮、主卡片、mini 卡片）在双主题下渲染快照测试
- [ ] T10 端到端实跑（必须由用户亲手验证，11 项验收清单）：
  - 启动 → 主窗口新视觉
  - 系统切换暗色 → Roosty 跟随
  - 首启 vault 卡片新视觉
  - 复制 URL → mini 卡片新视觉
  - 设置页所有元素新视觉
  - hover 按钮 → 投影微变（不是水波纹）
  - 点击按钮 → scale 微缩
  - 中文标题用思源宋体（视觉对比 Material 默认 Roboto + 雅黑）
  - 切深色后看暗色对比度（不眩光、不糊）
  - 关闭主窗口 → 隐藏到托盘（前面任务实现，不能被本次破坏）
  - 复制 URL → 端到端归档（M1 + M2 闭环不能被本次破坏）
- [x] T11 trellis-update-spec：把「设计 token 系统 + 主题分层规范」沉淀到 `frontend/component-guidelines.md` 或新建 `frontend/design-tokens.md`

---

## 关键约束

- **不改 M0 五接口签名**（`Source/Item/Fetcher/Processor/Sink`）
- **不破坏既有功能**：vault 自动发现、剪贴板捕获、mini 卡片、托盘、归档管线，全部必须仍工作
- **暗色不用纯黑 #000**，用 `#1F1B17`；文字不用纯白 #FFF，用 `#EDE5D8`
- **思源宋体子集化必须做**，否则包体涨 30MB 不可接受
- **Windows 字号下限 12px**（小字号 hinting 设 light），避免宋体糊
- **禁用 Material 水波纹**，自定义为色块 fade
- App UI 中文，代码注释/标识符英文
- 所有色值/间距/圆角必须走 token，**严禁硬编码**

## 范围外（roadmap，本任务不做）

- 主题手动切换（设置页提供「跟随系统/亮/暗」选择）—— 后续单独迭代
- Logo 重做 —— 后续单独迭代
- 自定义主题色 —— 用户能改 primary 色 —— 远期
- 微交互动效升级（spring/物理）—— 远期
- 国际化（i18n）—— 中文写死，远期

## 完成后

更新 checklist → trellis-update-spec → 主 session 驱动 commit → `/trellis:finish-work`。**T10 实跑必须由用户亲手验证 11 项后告知 GO，否则不许 finish-work。**

## 当前实现记录（2026-06-20）

- 已完成：`lib/theme/` token/theme/text 分层、亮/暗双主题、`ThemeMode.system`、Material 水波纹关闭、主窗口/首启卡片/设置页/忽略列表/历史/待确认卡片/mini 卡片的温暖手作视觉重做。
- 字体：下载 Adobe Source Han Serif SC 2.003R 与 Google Fonts Lora；Source Han Serif SC 用 `fonttools` 子集化为 GB2312 一级常用汉字 + 标点/数字/Latin + 当前 UI 文案；最终 `assets/fonts/` 四个字体文件合计约 5.8 MB。
- 对比度：关键组合均满足 WCAG AA：亮色正文 12.33:1、亮色次级文本 4.81:1、亮色主按钮 `onPrimary/primary` 4.76:1、暗色正文 13.69:1、暗色次级文本 5.36:1、暗色主按钮 7.07:1。
- 测试：新增 `test/theme_test.dart` 覆盖系统暗色 token、禁用 `ColorScheme.fromSeed`、mini 卡片双主题 token 表面；因视觉重排调整 `desktop_lifecycle_test.dart` 的退出按钮滚动定位。
- 验证：`flutter pub get`、`flutter analyze`、`flutter test`（49 项）、`flutter build windows` 已通过。
- 未通过/未完成：`flutter build apk --debug` 在 Gradle `:app:mergeDebugNativeLibs` 阶段失败，根因是 C 盘磁盘空间不足（Flutter Android JNI jar 解压报 `磁盘空间不足`）；T10 用户实跑仍待执行，完成前不能 finish-work。
