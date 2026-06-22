# Roosty 工程决策约束（Codex goal 执行的硬约束）

> 本文件是 `ROADMAP.md` 的补充，记录所有「写代码前已敲定、agent 不得自行更改」的工程决策。
> Codex goal 模式执行前必读。本轮 goal 范围 = **M0 + M1 + M2（桌面完整魔法）**。

---

## 本轮 goal 范围

- ✅ **做**：M0 项目骨架 → M1 桌面闭环 → M2 AI 摘要
- ❌ **不做**：M3 安卓分享（需真机/模拟器调试）、M4 开源发布（需开发者本人的 GitHub 账号、域名注册、push、录 GIF）
- 终点验收：在 Windows 上「复制网页链接 → 弹确认 → 归档成带 AI 摘要的 md 到 Obsidian vault」全链路实跑通过。

## 已锁定的关键决策（用户拍板）

| 项 | 结论 |
|----|------|
| 跑量范围 | M0–M2 桌面完整魔法 |
| 状态管理 | **Riverpod**（所有 UI + 管线状态用 Riverpod 组织） |
| 剪贴板捕获 | **复制 → 弹系统通知/应用内提示确认 → 用户点确认才归档**（不静默自动归档，兼顾魔法感与隐私） |
| 界面语言 | **App UI 中文**；**README + 代码注释 + 标识符英文** |

## 默认锁定项（agent 直接采用，无需再问）

- Flutter **stable** 通道，Dart 3.x。
- Android `applicationId` = `com.roosty.app`；工程/包名 `roosty`。
- 摘要语言**跟随原文**（中文文章出中文摘要，英文出英文）。
- 默认 LLM 示例：DeepSeek（`https://api.deepseek.com` + `deepseek-chat`），**key 由用户运行时填，代码中绝不硬编码**。
- 正文提取：优先用现成 readability 类 pub 包；抓不到则降级存「链接+标题」占位，不报错。
- 剪贴板监听**默认关闭**，首次启动引导用户：① 设置 vault 路径 ② 选择是否开启剪贴板监听。
- 文件名 slug：**保留中文**，仅去除 Windows 非法字符 `\ / : * ? " < > |`，重名追加序号。
- 测试：每个里程碑写最小单元测试（Pipeline 串联 / 文件名生成 / frontmatter 渲染 / 降级逻辑），`trellis-check` 会跑。
- 提交：每里程碑完成 auto-commit（Trellis 已配），**不主动 push**（push 留给用户）。
- LLM 调用超时 30s；失败/未配置 key 一律优雅降级，不阻塞归档。

## agent 跑不了、必须留给用户的事（M4，本轮不碰）

- 建 GitHub 组织（`roosty-io` / `roostyhq`）、`git push`、录演示 GIF。
- 注册 `roosty.io` 域名暂缓（成本考虑，2026-06-23 决定）；首发用 GitHub 仓库 URL。这些需要用户的账号和手动操作；M4 阶段 agent 只能把文件（README/LICENSE/配置示例/打包脚本）准备好。

## 品牌安全红线（全程不可越界）

- 全程零出现「Sherlockdogs / 侦探 / 狗 / 华生 / 线索」字样与视觉。
- Roosty 叙事只用「归巢 / roost / 鸟 / 巢」。名字、logo、文案全部原创。

---

## 给 Codex goal 的执行顺序

1. 读 `ROADMAP.md`（架构+schema）+ 本文件（约束）。
2. 按 `trellis:continue` 接当前 active task（M0）→ 完成 → `task.py finish` → `task.py start` 下一个 → 直到 M2 完成。
3. 每个里程碑严格按其 `prd.md` 的 checklist 施工，做完勾选。
4. 全程不改 M0 定义的接口签名（除非回 ROADMAP 更新决策）。

---

## 竞品定位（gemini 调研，2026-06-14，供 M4 README 用）

**名字 Roosty：全网无同名剪藏/稍后读/Obsidian 工具，无商标与认知冲突，安全。**

| 竞品 | 开源 | 短板（= Roosty 的机会） |
|------|------|----------------------|
| Cubox | ❌ 订阅 | 中心化云、数据不本地、高级功能收费 |
| Omnivore | ✅ | 托管已停；国内社媒水土不服；AI 摘要要自搭 |
| Hoarder | ✅ 自托管 | 偏书签存档，生成 md 无缝进 Obsidian 链路不直接 |
| Readwise Reader | ❌ 高价 | 中文社媒正文提取极差 |
| Obsidian 官方/MarkDownload Clipper | ✅ | 纯桌面扩展、无移动端分享菜单、只 HTML→MD 无 AI、打不过 SPA/反爬 |

**Roosty 的差异化三板斧（已被调研验证，与本规划吻合）：**
1. 移动端「系统分享接收器」——现有开源工具的最大空白（Roosty M3）。
2. 国内社媒特化解析（微信防盗链/小红书无头渲染/X）——开源最薄弱环节（Roosty M5 轻后端）。
3. Local-First + 自填 API Key（DeepSeek/通义等低成本模型）+ 强制结构化 YAML frontmatter（契合 Dataview）——与 DECISIONS 决策一致。

## 两端触发模型 ⏸ v1 暂缓 — 移动端代码冻结，恢复后此模型继续生效（2026-06-22）

> 本节描述完整的双端触发模型。**v1 不交付移动端**，本节内容作为未来恢复时的设计依据保留。

| 端 | 触发方式 | 行为 | 理由 |
|----|---------|------|------|
| **桌面** | 后台监听剪贴板（桌面系统允许） | **弹确认 → 归档** | 被动读用户复制的一切，必须确认（隐私） |
| **移动** | ① 系统分享菜单（用户主动分享） | **静默归档，不打断** | 用户已明确表意图，再确认啰嗦 |
| **移动** | ② 打开 App 时读一次剪贴板（前台、主动） | 弹确认 → 归档（可选功能） | 信噪比高，合规 |

**移动端明确不做「后台静默监听剪贴板」**，原因（事实）：
- Android 10+ 后台 App 无法读剪贴板（系统限制）；Android 12+ 前台读会弹系统 toast。
- 国内 App 普遍往剪贴板塞口令/链接，监听到的大量是垃圾，信噪比极低。
- 故移动端剪贴板只走「用户打开 App 时主动读一次 + 弹确认」，绝不后台常驻监听。

---

## 移动端暂缓决策记录（2026-06-22）

**决策**：v1 不交付移动端体验，但**代码与平台目录冻结保留在仓库中**，未来恢复时无需从零重建。

**这是暂缓决策（deferred），不是永久砍**。

### 理由

- v1 抢先开源目标对应的目标人群优先级：愿意用 Obsidian 做知识管理的桌面用户（中文 Windows 为主）。这部分人群的全部捕获需求在桌面端剪贴板就能满足。
- 移动端要做的事远不止 share intent：SAF 授权、APK 签名分发、应用商店审核、移动端剪贴板合规弹窗、不同 OEM ROM 兼容…对 v1 抢先目标是**重投入低杠杆**。
- 现存 APK 构建 C 盘空间问题（Android Gradle 忽略 E:\Temp 重定向，`mergeDebugNativeLibs` 阶段触顶）暂缓处理，等未来恢复时再统一解。

### 影响范围

冻结的代码资产（**不删除，加冻结注释**）：

- `lib/sources/share_intent_source.dart`
- `lib/sinks/android_saf_vault.dart`
- `lib/config/app_config.dart` 中 `androidVaultUri` 字段
- `lib/config/config_providers.dart` 中 `isAndroidProvider`
- `lib/ui/home_screen.dart` 中 `isAndroid` 分支
- `android/` 目录（Flutter 工程结构需要）
- `pubspec.yaml` 中 `receive_sharing_intent` 依赖（视编译影响评估）

桌面端共用 / 不受影响：剪贴板管线、`ClipboardSource`、`WebFetcher`、`SummarizeProcessor`、`ObsidianSink`（桌面分支）。

### 恢复条件（触发器）

任何一项满足时，重新评估是否启动移动端恢复：

1. 桌面版 v1 在公开渠道（GitHub Stars / 国内社群引用）达到一个可见的关注度，且**用户主动反馈缺少移动端**。
2. 社区贡献者主动接手 Android 端的接管与维护。
3. 主开发者完成 v1 后有空余时间，且当时市场仍无强竞品占位移动端。

### 恢复步骤要点（未来参考）

1. 先解 APK 构建 C 盘空间问题（Android Gradle 不读自定义 temp 环境变量）。
2. 移除所有 `// v1: deferred` 冻结注释。
3. 跑 R3 节的 `06-14-m4-opensource-release` PRD 时回填 Android APK 交付物。
4. 复活 ROADMAP §M3 的 ⏸ 标记，按原 T3.x 顺序施工。

### 不可逆判定

未来若决策"永久放弃移动端"，应：
- 删除上述冻结代码资产；
- 将本节标题改为"移动端废弃决策记录"；
- 移除 ROADMAP §M3 整段而非 ⏸ 标记。

**目前明确不是这种情况**。
