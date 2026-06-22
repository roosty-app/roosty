# Pre-Opensource Polish

> 开源发布前的最后一轮抛光：定型品牌视觉叙事、砍掉移动端 scope，让仓库首屏对得起"Roosty 归巢"这个隐喻。

## Goal

在 `06-14-m4-opensource-release` 之前，完成两件不可逆决策的落地，确保开源 demo 出去之后无需再大改方向：

1. **品牌视觉重塑**：把当前"工具型卡片列表"改成具象的"鸟巢/归巢"视觉叙事，让陌生人在第一帧 GIF 里就能读懂产品隐喻。
2. **暂缓移动端**：移动端目标人群偏小、开发/分发成本高，**暂时**退出 v1 scope；代码冻结保留，未来视情况恢复。

## Why Now

- 已完成的 UX 三件套（mini card 自绘窗 / 托盘生命周期 / 暖色主题）让产品**功能可用**，但**视觉与品牌叙事还停留在通用工具**层面。
- 开源 demo 出去后，README 截图 + 演示 GIF 是产品的第一印象；改主题已经做过一轮，再不收尾就会带着"半成品视觉"上 GitHub。
- 移动端代码还散落在 `lib/` 各处（`isAndroid` 分支、SAF 授权、`androidVaultUri` 配置字段）；与其长期维护两端代码、不如**冻结保留**，让 v1 专注桌面端，同时为未来恢复留好种子。

## Scope

### In Scope

| 子任务 | slug | 类型 | 交付物概述 |
|--------|------|------|-----------|
| 品牌视觉重塑 | `06-22-brand-visual-reframe` | 复杂任务 | 首屏信息架构重做、归巢隐喻落到 UI、mini card 视觉叙事强化、主入口能讲故事 |
| 暂缓移动端 scope | `06-22-drop-mobile-scope` | 轻量任务 | ROADMAP/DECISIONS/README 写明暂缓而非永久砍；移动端代码冻结保留并加恢复条件 |

### Out of Scope

- ❌ 修改桌面端核心管线（Source/Fetcher/Processor/Sink）的接口或行为
- ❌ 改主题底层 token（色板、间距、阴影、字体）—— 上一轮已锁定
- ❌ 注册域名 / 建 GitHub org / 推送（属于 `06-14-m4-opensource-release`）
- ❌ APK 构建 C 盘空间问题（移动端砍掉后自然消失，不单独修）
- ❌ 加新功能（剪藏新源、新 Fetcher、新 Sink）

## Cross-cutting Constraints

- 暖色手作主题 token 不动；色板、字体、阴影继续走 `RoostyTokens`。
- WCAG AA 不退；新加的视觉装饰元素必须在光/暗两套主题下都通过 token 渲染。
- mini card 380×200 固定尺寸不动。
- "Roosty 叙事只用归巢/roost/鸟/巢"红线继续生效（来自 DECISIONS.md §品牌安全红线）。
- 不引入新的桌面依赖（lottie、rive、第三方插画库）除非视觉重塑确实需要并在 design.md 写明。

## Acceptance Criteria

### 整体

- [ ] 两个子任务全部 archive 完成。
- [ ] `flutter analyze` 和 `flutter test` 通过。
- [ ] 在 Windows 上手动跑一遍主流程（启动 → 检测到 vault → 复制链接 → 弹 mini card → 归巢成功 → 看到历史）。

### 品牌视觉

- [ ] 首屏对陌生用户能在 5 秒内读出"这是把内容收进知识库"的产品意图，不需要看 README。
- [ ] mini card 视觉叙事可见"归巢"动作（不是无差别的工具弹窗）。
- [ ] 截一张主屏截图、一张 mini card 截图给 M4 demo 用，光/暗两套各一张。

### 暂缓移动端

- [ ] `ROADMAP.md`、`DECISIONS.md`、`README.md` 显式声明 v1 桌面优先，移动端**暂缓不交付**；附恢复条件 / 触发器。
- [ ] 代码层面对每个 Android 相关引用给出"冻结保留 / 桌面端共用"二选一的决策记录，**默认冻结，不删除**。
- [ ] `06-14-m4-opensource-release` 的 PRD 同步更新（移除 Android APK 交付物，标移动端为 future）。

## Children

- `06-22-brand-visual-reframe`（complex，需 prd + design + implement）
- `06-22-drop-mobile-scope`（lightweight，PRD-only 即可）

## Sequencing

子任务之间没有强依赖，但**建议先做 `drop-mobile-scope`** —— 暂缓移动端能让品牌视觉的设计聚焦在桌面单端，避免在 `brand-visual-reframe` 里反复纠结"这个隐喻在手机上是否成立"。

## Open Questions

无（决策已在父任务对齐：C 档大改 / 暂缓 Android 但代码冻结保留）。
