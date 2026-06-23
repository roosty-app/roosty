# Tray-Bound Flight Animation

> mini card 归巢动画的方向感要落到**真实托盘图标位置**，而不是飞向左上角虚空。

## Goal

修复 `brand-visual-reframe` Phase 4 留下的视觉缺陷：mini card 归巢/忽略时的退场动画当前飞向"屏幕左上角"，但**正常用户路径是主窗常驻托盘**——他们看不到主窗，只看到 mini card；卡片飞向左上虚空对他们来说没有目的地，破坏了"内容回到巢里"的语义。

正确的视觉是：mini card 飞向**屏幕上托盘图标的实际位置**，并由托盘图标做一次短暂闪烁回应"我接住了"。

## Why

- 主窗默认隐藏到托盘是产品的常态行为（已在 `desktop_lifecycle.dart` 实现：X 按钮 → hide-to-tray、托盘点击 → show/hide）。
- 用户感知到"归巢成功"的渠道当前只有：mini card 消失 + Obsidian 出现 .md。中间过程没有可视反馈。
- 飞向托盘的方向感把"消失"动作变成"被托盘接住"，让产品隐喻闭环。
- 这是一个**体验缺陷修复**，所以走 v1.0.1 patch release。

## Scope

### In Scope

1. **托盘坐标动态获取**：使用 `tray_manager` 提供的 `getBounds()` 或等价 API 拿托盘图标的屏幕坐标；任务栏在底/顶/左/右四种位置都能正确处理。
2. **mini card 退场动画方向调整**：从 mini card 当前位置 → 直线飞向托盘坐标 + 缩小 1.0→0.3 + 淡出。280ms，`Curves.easeInCubic`（沿用 design.md §4 现有曲线，仅换方向）。
3. **托盘图标接收反馈**：抵达后 500ms 内闪烁 2 次（用 `tray_manager.setIcon` 在两个 icon 之间切换）。
4. **同样的退场动画作用于「飞回巢」、「忽略一次」、「永不归档此域名」三个出口**——保持视觉一致性。
5. **patch release**：跑 build script 生成 `dist/roosty-windows-v1.0.1.zip`，更新 `pubspec.yaml` 版本号，发新 GitHub Release。

### Out of Scope

- ❌ 抛物线 / 旋转等更复杂动效（决策 §2 选 a，简单直线版）
- ❌ 主窗可见时切换为飞向主窗（决策 §4 选 a，行为一致）
- ❌ 改 mini card 380×200 尺寸 / 触发逻辑 / 按钮组
- ❌ 改主题 token / 修其他 UI bug
- ❌ Android / 移动端（仍冻结）

## Constraints

- 不引入新 pub 依赖；用 `tray_manager` 已有 API + 内置 Flutter 动画工具实现。
- 不能改 mini card 公共 API（`MiniCardModel` 形状、props、callback 签名）。
- WCAG / 主题 / 字体不退化；动画时长 ≤ 300ms 沿用 design-tokens spec。
- 不改 `lib/theme/`、`lib/core/`、`lib/sources/`、`lib/sinks/`、`lib/processors/`、`lib/config/`。
- 闪烁的"高亮 icon"用现有 `app_icon.ico` 的轻微变体（亮度 +20% 或染一下 `tokens.primary` 色调）；如果工时不够就用空白 icon 代替（淡入淡出本图标），不强求第二个 icon 文件。
- `tray_manager.getBounds()` 在 Windows 平台可能不存在或返回 null —— 需要 fallback 到"屏幕右下角"（任务栏默认位置），不能让动画完全失败。

## Requirements

### R1 — 实现飞行轨迹

- [ ] 在 `lib/ui/mini_card_window.dart` 中：
  - 获取托盘图标的屏幕坐标（封装一个内部 helper，例如 `Future<Offset?> _trayPosition()`，调用 `tray_manager` 相应 API）。
  - 计算 mini card 当前位置到托盘的位移向量。
  - 用 `Tween<Offset>` 把现有的 `Transform.translate` 改成飞向那个向量，配合现有 scale/opacity tween 不变。
- [ ] fallback：如果坐标为空，用屏幕右下方向（`Offset(+200, +200)`）作为兜底。
- [ ] 280ms / `Curves.easeInCubic` 曲线沿用，不改时长。

### R2 — 托盘图标闪烁反馈

- [ ] 在 `lib/ui/desktop_tray_bridge.dart` 中提供一个 `flashTrayIcon(Duration: 500ms, count: 2)` 公共方法。
- [ ] mini card 触发归巢/忽略动画的同时，调用 `flashTrayIcon`。
- [ ] 实现方式：`Timer` 每 125ms 切换 icon；500ms 后还原为默认 icon。
- [ ] 如果第二个高亮 icon 文件不存在，降级为"短暂隐藏 icon → 还原"也可接受。

### R3 — 三个出口动画一致

- [ ] 「飞回巢」/「忽略一次」/「永不归档此域名」三种 dismiss 路径共用相同的"飞向托盘 + 闪烁"序列。
- [ ] 不在 `MiniCardModel` / 上层 controller 中加分支判断，区别只在卡片上层。

### R4 — Patch Release

- [ ] `pubspec.yaml` 版本号 `1.0.0+1` → `1.0.1+2`。
- [ ] 跑 `scripts/build-windows.ps1` 生成 `dist/roosty-windows-v1.0.1.zip`。
- [ ] `gh release create v1.0.1 dist/roosty-windows-v1.0.1.zip --title "Roosty v1.0.1 — 托盘归巢动画" --notes "<release notes>"`。
- [ ] Release notes 描述这次的体验修复 + commit 链接。

### R5 — 验证

- [ ] `flutter analyze` 0 issue。
- [ ] `flutter test` 全部通过；新加 widget 测试覆盖 `flashTrayIcon` 调用次数（用 mock）。
- [ ] Windows 上手测：复制链接 → mini card 弹出 → 点"飞回巢" → 卡片明显朝托盘方向飞 + 缩小 + 淡出 → 托盘图标闪两下。
- [ ] 任务栏移到顶部/左侧再测一次（可选，但 design 期望验证至少两个位置）。

## Acceptance Criteria

- [ ] R1–R5 全部勾选。
- [ ] 用户使用产品时（主窗隐藏在托盘），点"飞回巢"能直观看出**卡片飞向托盘 + 托盘有反馈**。
- [ ] v1.0.1 Release 在 GitHub 上线。

## Risks

| 风险 | 应对 |
|------|------|
| `tray_manager` 在 Windows 拿不到 bounds | R1 已写 fallback；如果完全无 API 可用，至少能飞向"屏幕右下"——比飞向左上空白好 |
| 闪烁过强导致 Windows 通知中心打扰 | 总时长限制 ≤500ms / 闪烁 2 次足够看见但不烦人 |
| 第二个高亮 icon 文件做不出来 | 降级用现有 icon 短暂隐藏代替 |
| build-windows.ps1 在新版本号下出问题 | M4-α3 已经 fixed cwd + exit code 检查；本次复用即可 |
| 用户任务栏在自动隐藏状态 | tray_manager 拿到的坐标可能是隐藏前的——飞向那个方向也能接受，不算 bug |

## Notes

- 这是 lightweight 任务，PRD-only。
- 主要改动文件：`lib/ui/mini_card_window.dart`、`lib/ui/desktop_tray_bridge.dart`、`pubspec.yaml`。
- 完成后同步把"动画方向感要锚定到真实位置而非屏幕角落"沉淀进 `.trellis/spec/frontend/design-tokens.md` 作为新 anti-pattern。
