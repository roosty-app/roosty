# Brand Visual Reframe

> 把"归巢"从一个名字变成产品能讲出来的视觉故事。

## Goal

把当前"通用工具型卡片列表"升级成具象的**归巢叙事 UI**：用户进入 App 第一眼就能读到"我的内容像鸟一样飞回知识库"的产品意图，不需要看 README。

不重做主题色板、不改产品功能、不动管线接口。只动**信息架构、视觉叙事元素、动效语言**。

## Why

- 上一轮 `06-20-ui-visual-redesign` 完成了暖色手作主题 token + 视觉 bug 修复，产品**"看得下去"**。
- 但当前首屏（`lib/ui/home_screen.dart`）仍是一长串配置卡片：Vault / AI 摘要 / 捕获 / 应用 / 忽略列表 / 归巢历史。这是**工具型设置面板**，不是**产品**。
- mini card（`lib/ui/mini_card_window.dart`）做的是"看到一条链接"，但视觉表达和任何"剪藏弹窗"无差别，"归巢/鸟"的隐喻只在文案里出现一次。
- 开源发布前没人在意 demo GIF 是否好看；发布后第一波传播看的就是这个。

## Requirements

### R1 — 首屏信息架构重做（必做）

- [ ] 主屏顶部从"AppBar 文字 Roosty"升级为**品牌区**：标识 + tagline + "巢穴状态条"（连接的 vault、监听状态、归巢总数）。
- [ ] 主体从"6 个 Section 配置列表"重排为**两栏 / 双层结构**：
  - 上层：**今日归巢**（醒目展示最近 N 条已归巢内容，强 affordance 的视觉块，能看见"巢里堆积的内容")
  - 下层：**配置入口收敛**（vault / AI / 捕获开关聚合成一个紧凑面板，不再每个一个 Section）
- [ ] 配置入口默认折叠/收纳；首次进入未配 vault 时仍突出 Vault 引导（保留 `_VaultDiscoveryCard` 的强引导）。
- [ ] "忽略列表"和"退出 Roosty"收进二级（设置抽屉 / Tab / 折叠面板，由 design 决定）。

### R2 — 归巢隐喻视觉化（必做）

- [ ] 主屏空状态（无归巢历史）展示一个**视觉化的空巢**：手绘风插画或 token 化几何图形 + 引导文案"还没有内容飞回来"。
- [ ] 历史列表的视觉单位从"列表行"升级为"巢中堆叠"：每条内容像一根枝条/一只鸟落在巢里，按时间堆叠或并排展示，视觉上能"看出数量"。
- [ ] 选用 Flutter 原生 `CustomPaint` / 简单 `Stack` 组合实现，不引入 lottie/rive 等大依赖；插画允许用 SVG（通过 `flutter_svg` 引入，需在 design 评估）或纯几何图形。

### R3 — mini card 视觉叙事强化（必做）

- [ ] 当前 mini card 标题"Roosty 看到一条链接"改为更具情感的归巢化表达（具体文案在 design 里 brainstorm 3–5 候选）。
- [ ] 视觉上加一个**指向归巢的方向感**：例如左侧一个鸟/枝条/巢的小标识，或主按钮"归巢"用一个**飞向巢的箭头/微动效**强化方向。
- [ ] 归巢按钮点击 → 卡片消失的过程加入**飞入/淡出+下沉**的微动效（150–300ms，使用 Flutter `AnimatedSwitcher` / `TweenAnimationBuilder`，不引入新依赖）。
- [ ] 380×200 尺寸不变；现有按钮组（归巢 / 忽略一次 / 永不归档）功能与位置不变。

### R4 — 跨主题与可访问性（必做）

- [ ] 所有视觉装饰元素必须在**光主题和暗主题**下都正确渲染（颜色来自 `RoostyTokens`，不写死 `Color(0x...)`）。
- [ ] 新加文案保持中文，沿用 `SourceHanSerifSC` / `Lora` 字体栈。
- [ ] 新加交互元素满足 WCAG AA（4.5:1 文字 / 3:1 大文字 / 3:1 非文字图形）；不通过 AA 不上线。
- [ ] 不引入新依赖除非 design 阶段明确批准（候选：`flutter_svg`，仅在确认需要 SVG 插画时引入）。

### R5 — 文案与品牌一致（必做）

- [ ] 通读改动涉及的所有文案，确保只使用"归巢 / 巢 / 飞回 / 落下 / 枝条"等品牌词；不出现"剪藏 / 收藏 / 添加 / 入库"等通用词。
- [ ] tagline 候选在 design 给 3 条，最终在 implement 阶段定 1 条。
- [ ] 全程零出现 DECISIONS.md 红线词："Sherlockdogs / 侦探 / 狗 / 华生 / 线索"（已是上一轮约束，本任务继续遵守）。

### R6 — 截图与展示物（必做）

- [ ] 任务完成时在 `docs/screenshots/` 下产出 4 张定稿截图：
  - `home-light.png` — 主屏光主题
  - `home-dark.png` — 主屏暗主题
  - `mini-card-light.png` — mini card 光主题
  - `mini-card-dark.png` — mini card 暗主题
- [ ] 截图 1280×800 或更高分辨率，PNG 格式，可直接给 README 引用。

## Acceptance Criteria

- [ ] R1–R6 全部勾选。
- [ ] 完全陌生的用户打开 App 不读任何说明，能在 5 秒内得出"这是把内容收进我的知识库"的判断。
- [ ] `flutter analyze` 0 issue；`flutter test` 全部通过；新增 UI 组件有最小 widget test。
- [ ] 在 Windows 上手动跑主路径（vault 检测 → 复制链接 → mini card 弹出 → 归巢动效 → 历史显示）全程视觉无 glitch、动效不卡顿。
- [ ] 4 张截图 commit 到仓库且能直接用于 README。

## Out of Scope

- ❌ 改 `RoostyTokens` 底层 token（色板 / 字体 / 间距 / 阴影）—— 上一轮已锁定。
- ❌ 加新功能（新源、新 Sink、新 Fetcher、新设置项）。
- ❌ 引入 lottie / rive / 复杂 3D / 重型动画库。
- ❌ 接 iconfont / fontawesome 等图标库（继续用 Material Icons + 自绘）。
- ❌ 改 mini card 380×200 尺寸约束。

## Risks

| 风险 | 应对 |
|------|------|
| 视觉重塑边界感不清，做着做着变成重做产品 | design 阶段严格按 R1–R6 列项交付；超出范围的想法记到 Phase 2 backlog |
| 自绘插画质感差 / 不专业 | design 先评估两条路：纯 token 化几何 vs 引入 1–2 张 SVG；不行就回退到几何 |
| 动效卡顿（Windows + 软件渲染） | 限制单次 ≤300ms；用 Flutter 内置 `Curves`；不上 shader |
| 信息架构改大后老用户找不到忽略列表 / 退出 | implement 阶段保证二级入口可达且 ≤2 次点击 |
| 截图工具链不一致 | 用 Flutter 自带 `flutter screenshot` 或 Windows 自带工具，PNG 即可，不引入额外依赖 |

## Notes

- 这是 complex 任务，需 `prd.md` + `design.md` + `implement.md` 三件套。
- 实际视觉/动效细节、组件拆分、tagline 候选、文案候选都在 `design.md` 收口。
- 实际施工顺序、checkpoints、回滚点在 `implement.md` 收口。
