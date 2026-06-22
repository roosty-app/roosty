# Brand Visual Reframe — Design

> 把 PRD 的"归巢叙事"翻译成可施工的组件清单、信息架构、动效规格、依赖决策。

---

## 1. 信息架构

### 1.1 当前结构（要替换的）

`HomeScreen` → `Scaffold(AppBar: "Roosty")` → `ListView` 顺序堆叠 6 个 `_Section`：

```
[AppBar: Roosty]
  Section: Vault
  Section: AI 摘要
  Section: 捕获
  Section: 应用（退出）
  Section: 忽略列表
  Section: 归巢历史
[mini card overlay (Stack 右下角)]
```

问题：纯设置面板 + 历史在最底；首屏看不到产品在做什么。

### 1.2 新结构

```
[Scaffold]
└─ Body (CustomScrollView)
    ├─ NestHeader (sliver, 高度 ~140)
    │   ├─ 标识 + tagline (居左)
    │   └─ 巢穴状态条 (居右): vault名 · 监听灯 · "今日 N 条归巢"
    │
    ├─ NestStage (sliver, 主体)
    │   ├─ 空巢插画（history 为空时） / 巢中堆叠（有内容时）
    │   └─ 最近归巢卡片网格（最多 6 条；超出折叠成"查看全部 N 条"）
    │
    ├─ PendingCaptureBanner (sliver, 仅 captureState.pendingItem != null)
    │   └─ 复用现有 _PendingCapture 视觉，但移到 NestStage 下方
    │
    ├─ NestSettings (sliver, 折叠面板)
    │   ├─ ExpansionTile 默认收起；首次未配 vault 时强制展开 + 突出引导
    │   └─ 内含: Vault / AI / 捕获 / 忽略列表（紧凑布局）
    │
    └─ NestFooter (sliver, 高度 ~48)
        └─ 退出 Roosty (右下小按钮，不再单独一个 Section)

[mini card overlay] (沿用现有，视觉重塑见 §3)
```

### 1.3 状态分支

| 状态 | NestStage 渲染 |
|------|---------------|
| `history.isEmpty && pendingItem == null` | 空巢插画 + "还没有内容飞回来" + 引导文案 |
| `history.isNotEmpty` | 最近归巢网格（按时间倒序，每条一个 NestEntryCard） |
| `pendingItem != null` | NestStage 上方插入 PendingCaptureBanner（条带式） |
| 未配 vault | 顶层强制覆盖 `_VaultDiscoveryCard`（保留现有强引导逻辑） |

---

## 2. 组件拆分

新增组件全部放在 `lib/ui/nest/` 子目录下（与现有 `lib/ui/` 平级，但聚集本次叙事重塑相关）。

| 组件 | 文件 | 职责 |
|------|------|------|
| `NestHeader` | `lib/ui/nest/nest_header.dart` | 顶部品牌区 + 巢穴状态条 |
| `NestStatusStrip` | `lib/ui/nest/nest_status_strip.dart` | "vault名 · 监听灯 · 归巢计数"三段 |
| `NestStage` | `lib/ui/nest/nest_stage.dart` | 主体舞台（空状态/有内容两态） |
| `EmptyNest` | `lib/ui/nest/empty_nest.dart` | 空巢插画（自绘 / SVG） |
| `NestEntryCard` | `lib/ui/nest/nest_entry_card.dart` | 单条已归巢内容的展示卡 |
| `NestEntryGrid` | `lib/ui/nest/nest_entry_grid.dart` | 多条卡的堆叠/网格容器 |
| `NestSettings` | `lib/ui/nest/nest_settings.dart` | 折叠的设置面板（紧凑版 vault/ai/捕获/忽略列表） |
| `NestFooter` | `lib/ui/nest/nest_footer.dart` | 退出按钮等收尾 |
| `MiniCardWindow`（改造） | `lib/ui/mini_card_window.dart` | 现有文件，加方向感装饰 + 归巢动效 |

`HomeScreen` 改造：保留状态注入逻辑、文件路径不动；body 部分从平铺 6 个 Section 切换为 CustomScrollView + 上述 sliver。

---

## 3. 视觉叙事元素

### 3.1 空巢插画（EmptyNest）

**两条路评估**：

- **路径 A：纯 token 化几何**（默认选择）
  - 用 `CustomPaint` 画一个简化的"巢"：两条交叉的弧线（枝条）+ 三个椭圆（蛋）。
  - 颜色全部来自 `RoostyTokens`：枝条 `tokens.primary`，蛋 `tokens.bgElevated` + `tokens.divider` 描边。
  - 优点：零依赖，主题切换天然适配；缺点：质感受限。

- **路径 B：引入 SVG 插画 + `flutter_svg`**
  - 一张暖色手作风的简笔巢（约 200×120），双主题各一份或单色矢量动态着色。
  - 优点：质感更好；缺点：新依赖（包大小 +约 200KB）+ 主题适配要做 colorFilter。

**决策**：先走路径 A，做出来如果太丑再升级。引入 `flutter_svg` 需在 implement 第一步前回 PRD 经用户确认。

### 3.2 巢中堆叠（NestEntryGrid）

- 网格布局：`Wrap(spacing: tokens.space2, runSpacing: tokens.space2)`，单卡 `NestEntryCard` 宽度 ~280。
- 卡片视觉：圆角 `tokens.radiusLg`、`tokens.bgCard` 背景、`tokens.divider` 描边、`tokens.shadowSm` 阴影。
- 装饰：每张卡左上角放一个**小标记**——按 `item.source` 选 icon（沿用 mini card 的 `_sourceIcon` 逻辑），icon 颜色 `tokens.primary`。
- 内容：标题（titleSmall, 1 行省略）+ 摘要（bodySmall, 2 行省略）+ 底部 `tokens.textSecondary` 时间。
- "巢里堆积"的视觉感：第一张卡在最上方略大，后面递减少许阴影偏移；用 `Transform.translate` 给后续卡 +1px Y 偏移营造堆叠感（可选，design 阶段先按等高布局，效果不够再加）。
- 超出 6 张：底部一行 `TextButton` "查看全部 N 条" → 暂时只滚动到列表底部即可（不开新页面，YAGNI）。

### 3.3 巢穴状态条（NestStatusStrip）

```
[vault icon] vault名缩写 · [监听灯●] 监听中 · [鸟图标] 今日归巢 N 条
```

- vault 名缩写：路径最后一级目录名，超长省略。
- 监听灯：`Container` 直径 8 圆点；`tokens.success` 表示开启，`tokens.textDisabled` 表示关闭。
- 归巢计数：`captureState.history` 中今日条数。

### 3.4 mini card 装饰

- 标题文案（候选 3 条，implement 阶段定 1）：
  - "一只链接落到了枝头"
  - "Roosty 接到一条归巢请求"
  - "枝头来了一条新内容"
- 左上角：保持现有 source icon，但改成 `Stack`：底层一个圆形 `tokens.primarySubtle` 背景 + 上层 source icon `tokens.primary`，营造"鸟落枝"的视觉锚点。
- "归巢"主按钮：现有 `FilledButton.icon(icon: Icons.archive)` → 改为带方向感的 icon（`Icons.arrow_outward` 旋转 / 自绘箭头朝向左上角的巢） + 文案"飞回巢"。
- 380×200 尺寸**不变**；padding 与 token 不变。

---

## 4. 动效规格

| 元素 | 触发 | 动效 | 时长 | 曲线 |
|------|------|------|------|------|
| mini card 出现 | `MiniCardWindow` 首次构建 | 从右下角滑入 + 淡入 | 220ms | `Curves.easeOutCubic` |
| mini card 归巢 | 用户点"飞回巢" | 卡片向左上方平移 24px + 淡出 + 略缩小 | 280ms | `Curves.easeInCubic` |
| mini card 忽略 | 用户点"忽略一次"/"永不归档" | 直接淡出 | 160ms | `Curves.easeOut` |
| NestEntryGrid 入场 | 历史首次加载 | 卡片逐张错位淡入（stagger 50ms） | 单卡 200ms | `Curves.easeOut` |
| 空巢 → 有内容切换 | 第一条历史落入 | `AnimatedSwitcher` 交叉淡变 | 240ms | `Curves.easeInOut` |

实现工具：`AnimatedSwitcher`、`AnimatedOpacity`、`TweenAnimationBuilder`、`AnimatedSlide`、`AnimatedScale`。**不引入新依赖**（`flutter_animate` 等不需要）。

---

## 5. 文案候选

### 5.1 Tagline

implement 阶段从这 3 条选 1：

- "把散落的内容叼回知识库"
- "让链接像鸟一样飞回你的 Obsidian"
- "归巢，一切就此安顿"

### 5.2 空巢引导

- 主文："还没有内容飞回来"
- 副文："复制一条链接，Roosty 会接住它"

### 5.3 监听灯状态

- 开启：`监听中`
- 关闭：`未监听`
- 临时停用（domain 屏蔽）：`暂停 · X 个域名忽略`

### 5.4 mini card 标题（同 §3.4）

3 选 1。

---

## 6. Token 使用规约

仅使用现有 `RoostyTokens`。本任务**不**新增 token。需要时优先复用：

| 用途 | Token |
|------|-------|
| 主体背景 | `tokens.bgBase` |
| 卡片背景 | `tokens.bgCard` |
| 区域强调 / hover 浅底 | `tokens.primarySubtle` |
| 主品牌色（图标 / 强调） | `tokens.primary` |
| 描边 / 分割线 | `tokens.divider` |
| 阴影（卡片） | `tokens.shadowSm` / `tokens.shadowMd` |
| 主文 | `tokens.textPrimary` |
| 次文 / 时间 / 副文 | `tokens.textSecondary` |
| 状态成功 | `tokens.success` |
| 状态错误 | `tokens.error` |

---

## 7. 跨主题验证矩阵

| 组件 | 光主题 | 暗主题 |
|------|--------|--------|
| NestHeader | tokens 渲染 | tokens 渲染 |
| EmptyNest 自绘 | 颜色全部走 token | 颜色全部走 token |
| NestEntryCard | tokens.bgCard / divider / shadowSm | 同 |
| mini card 装饰 | primarySubtle 圆背景在 cream 上 ≥3:1 对比 | primarySubtle 在暗底上 ≥3:1 |
| 监听灯 | success/textDisabled 圆点 | 同 |

每个组件 implement 阶段必须双主题手测一次（用 `ThemeMode.light` / `ThemeMode.dark` 临时强制）。

---

## 8. 数据流影响

**零改动**。所有新组件读 `ref.watch(...)` 的 provider：

- `appConfigControllerProvider`（vault path / 监听开关）
- `captureControllerProvider`（history / pendingItem）
- `miniCardControllerProvider`（cards）

provider 接口、state 形状、controller 行为**全部不动**。

---

## 9. 测试策略

### 9.1 单元 / Widget Tests（必做）

- `test/ui/nest/empty_nest_test.dart` — 自绘巢 widget 在两套主题下都构建无 error。
- `test/ui/nest/nest_entry_card_test.dart` — 给定 `Item` 渲染出标题 + 摘要 + 时间。
- `test/ui/nest/nest_stage_test.dart` — 空 history 显示 EmptyNest；非空显示 Grid；两态切换 widget tree 正确。
- `test/ui/nest/nest_status_strip_test.dart` — 监听开/关/暂停三态文案与颜色。

### 9.2 已有测试保护

- 现有 `test/desktop_lifecycle_test.dart` 必须继续通过。
- 现有 widget tests（如 home_screen 相关）按需更新；如果改 `HomeScreen` 树结构破坏现有 finder，更新 finder 而非删测试。

### 9.3 手动验证

- Windows 实跑：vault 检测 → 复制链接 → mini card 弹出 + 入场动效 → 点"飞回巢" → 归巢动效 → NestStage 出现新 entry。
- 切换系统主题：光/暗主题下的视觉双向验证。
- 截图：4 张定稿截图（PRD R6）。

---

## 10. 依赖决策

| 候选依赖 | 决策 | 理由 |
|---------|------|------|
| `flutter_svg` | **暂不引入** | 路径 A 优先；引入需 PRD 经用户确认 |
| `flutter_animate` | 不引入 | 内置 AnimatedSwitcher / TweenAnimationBuilder 够用 |
| `lottie` / `rive` | 不引入 | PRD 明确 out of scope |
| `flutter_staggered_animations` | 不引入 | stagger 用 `Future.delayed` + 索引 + `AnimatedOpacity` 自实现 |

---

## 11. 影响面 / 兼容性

- `lib/ui/home_screen.dart` 重构 body；保留所有现有 controller 注入与 lifecycle/tray bridge。
- `lib/ui/mini_card_window.dart` 改装饰与按钮文案 / 动效；不动尺寸、外部 props、`MiniCardModel` 形状。
- `lib/ui/nest/` 新增 8 个文件。
- 现有测试基本不受影响；如果 `HomeScreen` 树深破坏现有 widget test 的 finder，按 §9.2 更新。
- 不动 `lib/core/`、`lib/sources/`、`lib/sinks/`、`lib/processors/`、`lib/config/`。
- 不动 `lib/theme/tokens.dart`。

## 12. 回滚计划

每个 phase（见 implement.md）独立 commit；任何 phase 出现严重视觉缺陷或测试退化，单独 revert 该 commit即可。

`HomeScreen` 重构是单点风险——把 body 提取为独立 widget（`NestBody`），出错时可一行切回旧 `_HomeContent`。

---

## 13. Open Questions

- 退出按钮藏到哪一级？候选：a) NestSettings 折叠面板末尾；b) NestFooter 右下角文字按钮。**design 倾向 b**——日常操作不该藏太深。implement 阶段最终定。
- 空巢插画**是否需要轻微呼吸动效**（缩放 1.0 ↔ 1.02 循环 3s）？倾向不加，避免分散注意力。implement 阶段视觉看一眼再定。
