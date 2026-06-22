# Drop Mobile Scope (Deferred, Not Killed)

> v1 桌面 only。Android **暂时退出** v1 scope，代码与平台目录冻结保留，未来恢复时无需从零再来。

## Goal

把"暂时砍移动端"这个**临时性产品决策**落到代码、文档、任务三个层面：
- v1 开源仓库以**桌面优先工具**面貌发布；
- 移动端代码 **不删除**，整体冻结到 `mobile/` 子目录或加冻结标记，未来重启时可一键复活；
- 文档明确写"deferred / 暂缓"，不是"永久砍"，避免对外或对自己传递"方向不清晰"信号。

## Why

- v1 目标人群优先级：愿意用 Obsidian 做知识管理的桌面用户（中文 Windows 为主）—— 这部分人群的全部捕获需求都能在桌面端被剪贴板满足。
- 移动端要做的事远不止 share intent：SAF 授权、APK 签名分发、应用商店审核、移动端剪贴板合规弹窗、不同 OEM ROM 兼容…对 v1 抢先开源目标是**重投入低杠杆**。
- 现存 APK 构建已知问题：Android Gradle 忽略 E:\Temp 重定向，`mergeDebugNativeLibs` 阶段 C 盘空间触顶。**暂缓**不修，等未来恢复移动端时再统一处理。
- 但**保留代码资产**：已有的 `share_intent_source.dart` / `android_saf_vault.dart` / `androidVaultUri` 配置 / `android/` 工程目录都是未来重启的种子；删干净等于把已经付出的工时丢掉。

## Requirements

### R1 — 文档同步（必做）

- [ ] `ROADMAP.md` §1 北极星目标的"项目级目标"中，"跨端一套码：Flutter 覆盖 Android + Windows" 改为 "**v1 桌面优先**：Flutter 覆盖 Windows；Android 已有代码冻结保留，恢复时间待定"。
- [ ] `ROADMAP.md` §2 锁定决策总表 第 4 行（首发平台）改为 "**v1 单端首发：Windows**；Android（已有代码冻结）/ Mac / iOS → 后续 roadmap"。
- [ ] `ROADMAP.md` §4 Milestones 中：
  - M3 安卓分享菜单**整体改为"⏸ 暂缓（v1 不交付，代码已冻结保留）"**，不降到 M5+。
  - M4 完成标准里的"Android APK 挂 Release"删除；只保留 Windows 安装包。
- [ ] `ROADMAP.md` §5 任务节点 M3 安卓分享菜单四个 T3.x 任务全部加 **⏸ 暂缓** 前缀（不移走，原位标注，避免改幅过大）。
- [ ] `ROADMAP.md` §6 风险与对策中"iOS 上架审核拖慢节奏"、"移动端 vault 沙盒访问受限"两行加备注 "（v1 不适用，移动端暂缓）"，**不删除**。
- [ ] `DECISIONS.md` 增加 §移动端暂缓决策记录小节，写明决策时间（2026-06-22）、**临时性**理由、影响范围、**恢复条件 / 触发器**（什么情况下重启移动端：例如桌面端达到 X 名用户、社区贡献者主动接手、等等）。
- [ ] `DECISIONS.md` §两端触发模型整段标注 "⏸ v1 暂缓 — 移动端代码冻结，恢复后此模型继续生效，2026-06-22"。
- [ ] `README.md` 主体内容声明 v1 是桌面优先工具；在 Roadmap / Future Work 区块中显式提到 Android 代码已存在但未启用，欢迎贡献者接手。

### R2 — 代码层面冻结策略（必做，不删代码）

**统一策略：冻结而非删除**。所有 Android / 移动端相关代码原地保留，加冻结标记，运行时与桌面端互不干扰。

具体处理分两类：

- **冻结但保留（F）**：保留文件，加顶层注释 `// v1: deferred — see DECISIONS.md §移动端暂缓`；如果该模块会被 main 注入，改为"未启用时空实现"或"桌面端编译期跳过"。
- **桌面端共用（K）**：被桌面端调用，与移动端无关，原样保留。

预计的分类参考（实际归类在 implement 时逐文件验证）：

| 文件 / 引用 | 决策 | 处理 |
|------|------|------|
| `lib/sources/share_intent_source.dart` | F | 顶层加冻结注释；如果 main 注入，确保桌面端跳过初始化 |
| `lib/sinks/android_saf_vault.dart` | F | 顶层加冻结注释；桌面端 ObsidianSink 不调用，无影响 |
| `lib/config/app_config.dart` 中 `androidVaultUri` 字段 | F | 字段保留；桌面端不读写；JSON 序列化仍兼容 |
| `lib/config/config_providers.dart` 中 `isAndroidProvider` | F | provider 保留；桌面端永远返回 false（已是当前行为） |
| `lib/ui/home_screen.dart` 中 `isAndroid` 分支 | F | 分支保留（永远走不到桌面端）；但本任务范围内不改 UI 树（UI 改造在 `brand-visual-reframe` 处理） |
| `pubspec.yaml` 中 `receive_sharing_intent` 依赖 | F → 评估 | 默认保留依赖；如果体积影响明显或冻结状态下编译失败，再考虑 conditional 处理 |
| `android/` 目录（Flutter 生成） | F | 不删（Flutter 工程结构需要）；README/ROADMAP 声明 v1 不打 APK、不分发 |
| `lib/sources/clipboard_source.dart`、桌面端管线核心 | K | 桌面端依赖，原样保留 |

**冻结注释模板**：

```dart
// v1: deferred — mobile/Android features are frozen but preserved.
// See DECISIONS.md §移动端暂缓 for restoration conditions.
```

### R3 — 任务联动（必做）

- [ ] `06-14-m4-opensource-release` 任务的 `prd.md` 同步：
  - 移除"打包 Android APK 挂 Release"。
  - 标题或描述加"v1 桌面优先"修饰；移动端列入 future scope。
- [ ] 已 archive 的移动端遗留任务（如有）不动；此次决策只对未来有效。

### R4 — 验证（必做）

- [ ] `flutter pub get` 通过（依赖未删，应无变化；如评估后删了依赖则需重测）。
- [ ] `flutter analyze` 无 warning / error；冻结注释不引入新 lint。
- [ ] `flutter test` 全部通过（包括移动端原有测试，如有，应继续通过——因为代码未删）。
- [ ] `flutter run -d windows` 启动正常，主路径（vault 检测 → 剪贴板归巢 → 历史显示）不变。
- [ ] 全仓搜索 `isAndroid`、`androidVaultUri`、`receive_sharing_intent`、`SAF`、`share_handler`：每处引用都能映射到 R2 表格中某一行的决策（F 或 K）。

## Acceptance Criteria

- [ ] R1–R4 全部勾选。
- [ ] 任何陌生贡献者读完更新后的 ROADMAP + README + DECISIONS，能在 1 分钟内得出：
  - "v1 不交付移动端"；
  - "移动端代码已存在并冻结"；
  - "未来可恢复"（即不是永久砍）。
- [ ] 改动挂在 1–2 个 commit 里（doc commit + 注释 commit），diff 干净。
- [ ] 移动端代码量零删除（除非 implement 阶段发现某文件 100% 是 dead import 才单独处理）。

## Out of Scope

- ❌ 删除任何移动端核心文件（`share_intent_source.dart` / `android_saf_vault.dart` 等）。
- ❌ 删除 `android/` 目录。
- ❌ 修改桌面端管线接口、行为。
- ❌ 改 mini card / 主题视觉（这是兄弟任务 `brand-visual-reframe` 的事）。
- ❌ 写"未来恢复移动端"的详细迁移指南（YAGNI，DECISIONS 一行恢复条件够用）。

## Risks

| 风险 | 应对 |
|------|------|
| 冻结的 Android 依赖在桌面端 `flutter pub get` 时拖慢或失败 | 默认保留依赖；如果出现失败，按 conditional dependency 处理（按平台拆分），仍不删依赖项 |
| 冻结后下次有人启用 Android 编译，APK 构建 C 盘空间问题再次出现 | DECISIONS 的恢复条件中显式记一笔"恢复时先解 APK 构建 C 盘空间问题" |
| ROADMAP/DECISIONS 改幅大引发 review 难度高 | 用 "⏸ 暂缓" 前缀而非整段删除/重写；保留原文，最小化 diff |
| 冻结注释贴满代码后，工程师后续不知道是否还在维护 | 注释模板里链回 DECISIONS.md 锚点，单点真相 |

## Notes

- 这是 PRD-only 的轻量任务，无独立 design.md / implement.md。
- 实际归类决策（D/F/K）在 implement 阶段逐文件确认；本 PRD 只给出候选清单。
