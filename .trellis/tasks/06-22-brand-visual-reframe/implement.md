# Brand Visual Reframe — Implement

> 把 design.md 的组件清单切成可逐步交付的 phase，每个 phase 有 checkpoint + 验证 + 回滚点。

---

## Phase 0 — 前置（< 30 分钟）

**目标**：确认现状、建好目录骨架、不动逻辑。

- [ ] 0.1 在 `lib/ui/` 下新建 `nest/` 子目录（用 `.gitkeep` 占位文件先 commit，或随 phase 1 一起进）。
- [ ] 0.2 跑 `flutter analyze` + `flutter test` 拿一份基线，记录通过条目数，作为后续退化对比基准。
- [ ] 0.3 跑 `flutter run -d windows`，手测主路径，记录基线表现。

**Checkpoint**：基线绿；任何当前未通过的测试在动手前列出并问用户怎么办。

**回滚**：无改动，无需回滚。

---

## Phase 1 — NestHeader + NestStatusStrip（约 1h）

**目标**：先把顶部品牌区做出来；不动主体，保证 main 流不破。

- [ ] 1.1 写 `lib/ui/nest/nest_status_strip.dart`：
  - `NestStatusStrip({required this.vaultName, required this.isWatching, required this.todayCount})`
  - 三段：vault icon + 名称 / 监听灯（圆点） / 今日 N 条归巢
  - 颜色完全走 tokens
- [ ] 1.2 写 `lib/ui/nest/nest_header.dart`：
  - 高度约 140
  - 左侧：标识 "Roosty"（Lora 字体）+ tagline（implement 阶段选定 1 条候选）
  - 右侧：`NestStatusStrip`
- [ ] 1.3 修改 `lib/ui/home_screen.dart`：把 `AppBar(title: const Text('Roosty'))` 替换为 `NestHeader`（暂时让原 body 继续显示，验证 header 单独可用）。
- [ ] 1.4 写 widget test `test/ui/nest/nest_status_strip_test.dart`（监听开/关两态各一断言）。
- [ ] 1.5 `flutter analyze` + `flutter test`；Windows 实跑确认 header 渲染正常。

**Checkpoint**：header 出现在主屏顶部，原 6 个 Section 仍在下方堆叠（过渡态可接受）。

**回滚**：单 commit `feat(ui): nest header`，revert 即可。

---

## Phase 2 — NestEntryCard + NestEntryGrid + EmptyNest（约 1.5h）

**目标**：搭出主体舞台的两个状态，但暂时挂在 home_screen 顶部，不替换现有 Section 列表。

- [ ] 2.1 写 `lib/ui/nest/nest_entry_card.dart`：
  - props: `Item item`
  - 280 宽，使用 `tokens.bgCard` / `radiusLg` / `shadowSm` / `divider`
  - 左上 source icon，标题（1 行省略），摘要（2 行省略），底部时间（`tokens.textSecondary`）
- [ ] 2.2 写 `lib/ui/nest/nest_entry_grid.dart`：
  - props: `List<Item> items, int maxVisible = 6`
  - 用 `Wrap` 排列；超出 maxVisible 后底部 TextButton "查看全部 N 条"（暂时无副作用）
- [ ] 2.3 写 `lib/ui/nest/empty_nest.dart`：
  - 走路径 A（纯 token 化几何）：`CustomPaint` 画两条弧线（枝条）+ 三个椭圆（蛋）
  - 下方文案："还没有内容飞回来" / "复制一条链接，Roosty 会接住它"
  - 双主题 token 化
- [ ] 2.4 写 `lib/ui/nest/nest_stage.dart`：
  - props: `List<Item> history`
  - `AnimatedSwitcher` 在 empty/non-empty 之间切换（duration 240ms）
- [ ] 2.5 写 widget tests：
  - `test/ui/nest/empty_nest_test.dart`
  - `test/ui/nest/nest_entry_card_test.dart`（给定 Item 渲染断言）
  - `test/ui/nest/nest_stage_test.dart`（empty / non-empty 两态切换断言）
- [ ] 2.6 在 `home_screen.dart` 的 ListView 顶部（Header 之下、Section 列表之上）临时插入 `NestStage(history: captureState.history)`。
- [ ] 2.7 `flutter analyze` + `flutter test`；Windows 实跑：
  - 空 history 时看见空巢
  - 复制一条链接走完归巢流程后，NestStage 出现新 entry
- [ ] 2.8 视觉手测：空巢插画在光/暗主题下都成立？不成立则走 design §3.1 路径 B 兜底（仍需回 PRD 经用户确认依赖）。

**Checkpoint**：主舞台两态都能正常切换；现有 Section 列表还在下面但已经不是主角。

**回滚**：单 commit `feat(ui): nest stage with empty + grid`。

---

## Phase 3 — NestSettings 收纳 + NestFooter（约 1h）

**目标**：把现有 6 个 Section 折叠成 NestSettings + NestFooter，完成信息架构闭环。

- [ ] 3.1 写 `lib/ui/nest/nest_settings.dart`：
  - 默认收起的 `ExpansionTile`（标题 "设置"）
  - 内部紧凑布局：Vault 行 + AI 行 + 捕获开关 + 忽略列表
  - **首次进入未配 vault 时强制展开 + 在 NestStage 上方插入引导**（沿用 `_VaultDiscoveryCard`，design §1.3）
  - 控件保留原有 `controller` 注入与回调（从 `HomeScreen` 透传，不改 controller 接口）
- [ ] 3.2 写 `lib/ui/nest/nest_footer.dart`：
  - 右下角 `TextButton.icon`（`Icons.power_settings_new` + "退出 Roosty"）
  - 颜色 `tokens.error`
  - onPressed: 透传 `onExitApp`
- [ ] 3.3 改造 `home_screen.dart`：
  - 把原 6 个 `_Section` 调用全部删除
  - body 改为 `CustomScrollView` + sliver：`NestHeader` → `NestStage` → `_PendingCapture`（仍保留） → `NestSettings` → `NestFooter`
  - `_VaultDiscoveryCard` 在 vault 未配时插在 NestStage 之上
  - 现有 `_Section` / `_HistoryTile` / `_BlockedDomainTile` / `_PendingCapture` / `_EmptyState` 中**复用**到 NestSettings 里的部分继续保留；其余按需删除
- [ ] 3.4 验证 `_HistoryTile`：原"归巢历史"Section 已被 NestStage 替代；老的 `_HistoryTile` 类如果不再被引用，删除并清理 import。
- [ ] 3.5 widget test：home_screen 顶层结构存在 `NestHeader` / `NestStage` / `NestSettings` / `NestFooter` 四个 finder。
- [ ] 3.6 `flutter analyze` + `flutter test`；Windows 实跑：
  - 主路径仍走通
  - 设置抽屉默认收起；点开后 Vault / AI / 捕获 / 忽略列表都能用
  - 未配 vault 时强引导出现
  - 退出按钮可用

**Checkpoint**：首屏完全是新结构；老的工具型 6-Section 已消失。

**回滚**：单 commit `feat(ui): collapse settings into nest layout`。这一步动得最多，可以分两步 commit：先 NestSettings 替换，再 NestFooter；视实际改动量决定。

---

## Phase 4 — mini card 视觉叙事强化（约 1h）

**目标**：mini card 加方向感装饰 + 归巢动效。

- [ ] 4.1 修改 `lib/ui/mini_card_window.dart`：
  - 标题文案改为定稿候选（3 选 1）
  - 左上 source icon 用 `Stack`：底层圆形 `tokens.primarySubtle`（直径 28）+ 上层原 source icon（`tokens.primary`，size 18）
  - "归巢"主按钮：icon 改为 `Icons.arrow_outward`（或自绘箭头朝左上）+ 文案 "飞回巢"
- [ ] 4.2 在 `MiniCardDeck` 外层加入场动效：
  - 包一层 `AnimatedSlide` + `AnimatedOpacity`，cards 出现时从右下角滑入 + 淡入（220ms, easeOutCubic）
- [ ] 4.3 在 `MiniCardWindow` 内部为归巢动作加退出动效：
  - 用 `AnimatedSwitcher` + `Tween<Offset>` 让被归巢/忽略的卡片向左上方平移 + 淡出 + 略缩小（280ms, easeInCubic）
- [ ] 4.4 widget test 不增（动效靠手测）；现有 mini card 测试如果断言文案需更新。
- [ ] 4.5 `flutter analyze` + `flutter test`；Windows 实跑：
  - 复制链接 → mini card 滑入
  - 点"飞回巢" → 卡片飞向左上 + 淡出
  - 点"忽略一次" → 直接淡出
  - 380×200 尺寸未变；按钮排布未变

**Checkpoint**：mini card 视觉与"归巢"叙事一致；功能未退化。

**回滚**：单 commit `feat(ui): nest narrative on mini card`。

---

## Phase 5 — 双主题手测 + 截图（约 30min）

**目标**：交付 4 张定稿截图。

- [ ] 5.1 临时把 `MaterialApp.themeMode` 改为 `ThemeMode.light`，跑 Windows，截图：
  - `docs/screenshots/home-light.png`
  - `docs/screenshots/mini-card-light.png`（让 mini card 弹出再截）
- [ ] 5.2 改为 `ThemeMode.dark`，跑 Windows，截图：
  - `docs/screenshots/home-dark.png`
  - `docs/screenshots/mini-card-dark.png`
- [ ] 5.3 改回 `ThemeMode.system`。
- [ ] 5.4 截图保存 1280×800 或更高，PNG 格式。
- [ ] 5.5 commit `docs(screenshots): brand visual reframe set`。

**Checkpoint**：4 张截图可直接用于 README。

**回滚**：仅 `docs/` 改动，安全。

---

## Phase 6 — 收尾（约 30min）

- [ ] 6.1 全仓搜索改动可能遗漏的旧引用：
  - `Roosty 看到一条链接` → 应不存在
  - 旧 `_HistoryTile` / `_Section` 残留 import → 清理
- [ ] 6.2 `flutter analyze` 应 0 issue；如有 warning 修复。
- [ ] 6.3 `flutter test` 全部通过；新增的 widget tests 覆盖 4 个新组件（NestStatusStrip / EmptyNest / NestEntryCard / NestStage）。
- [ ] 6.4 commit `chore: lint cleanup for brand visual reframe`（如有）。
- [ ] 6.5 准备 finish-work 所需的 implementation record（PRD §6 截图、design §10 依赖决策、动效曲线确认表）。

**Checkpoint**：PRD R1–R6 自检全部勾选。

---

## 验证命令清单（每个 phase 末尾跑一次）

```powershell
flutter analyze
flutter test
flutter run -d windows
```

`flutter test` 应至少新增 4 个 widget test：
- `test/ui/nest/nest_status_strip_test.dart`
- `test/ui/nest/empty_nest_test.dart`
- `test/ui/nest/nest_entry_card_test.dart`
- `test/ui/nest/nest_stage_test.dart`

---

## Review Gates

- **Phase 2 末尾**：空巢插画路径 A 是否成立？不成立 → 暂停，回 PRD 经用户确认是否引入 `flutter_svg`。
- **Phase 3 末尾**：设置抽屉默认收起是否影响新用户上手？如果未配 vault 时引导不够强 → 调整为强制展开 + 高亮 Vault 行。
- **Phase 5 末尾**：4 张截图给用户看一眼再 commit；不通过则回 Phase 1–4 调整。

---

## Phase-level 提交策略

每个 phase 一个独立 commit，message 形式：

- Phase 1: `feat(ui): nest header with brand and status strip`
- Phase 2: `feat(ui): nest stage with empty illustration and entry grid`
- Phase 3: `refactor(ui): collapse settings into nest layout`
- Phase 4: `feat(ui): nest narrative animations on mini card`
- Phase 5: `docs(screenshots): brand visual reframe set`
- Phase 6: `chore: lint cleanup for brand visual reframe`

总改动预计 6 个 commit；如某 phase 实际拆成多 commit 也可（例如 Phase 3 拆为 settings + footer）。

---

## 预计总耗时

约 4.5–5.5 小时（不含调试/视觉迭代）。如果路径 A 走 SVG 路径 B，加 +1h。

---

## Out of Scope（再次提醒）

不改 token、不改管线、不引入新依赖（除非 Phase 2 末尾 design §3.1 路径 B 升级且经 PRD 确认）、不改 mini card 380×200。
