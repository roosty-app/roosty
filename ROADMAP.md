# Roosty 开发规划

> 把散落各处的内容「叼回」你自己的知识库。
> Roost = 鸟归巢栖息。Roosty 是一个跨端的「内容归巢」工具：转发 / 复制一条内容，它自动抓取、结构化、摘要，归档进你的 Obsidian 库。

---

## 1. 北极星目标

**核心魔法（必须在 demo 里一眼炸裂）：**
> 用户在手机上把一篇微信文章「分享到 Roosty」（或在电脑上复制一条链接），几秒后他的 Obsidian 库里就出现一篇**带 AI 摘要、自动标签、来源信息**的结构化笔记。

**项目级目标：**
- **抢先开源**：在对方（Sherlockdogs）发布前，把这个功能做出来并开源传播。
- **零门槛可跑**：开源用户 `git clone` + 填一个 vault 路径（+ 可选 LLM key）即可运行，无平台审批、无封号风险、无需自建后端。
- **v1 桌面优先**：Flutter 覆盖 Windows；Android 已有代码冻结保留，恢复时间待定，详见 [`DECISIONS.md`](./DECISIONS.md) §移动端暂缓。iOS/Mac 后续 roadmap。

**非目标（明确不做，防止发散）：**
- ❌ 不做 RAG / 知识库对话（交给 Obsidian 的 Copilot 等插件）。
- ❌ 不做 Agent 执行任务（那是另一个产品）。
- ❌ 不碰微信个人号协议 / 公众号接口（开源场景下是死路）。
- ❌ MVP 不死磕全平台完美抓取正文（无底洞）。

---

## 2. 锁定决策总表

| # | 决策点 | 结论 |
|---|--------|------|
| 1 | 产品定位 | 内容**归集器**（非 AI 引擎） |
| 2 | 品牌名 | **Roosty**（域名 .io/.dev/.ai/.co 可注册；pub.dev/npm 空） |
| 3 | 入口 | 移动端=系统**分享菜单**；桌面端=**剪贴板监听** |
| 4 | 首发平台 | **v1 单端首发：Windows**；Android（已有代码冻结）/ iOS / Mac → 后续 roadmap |
| 5 | 技术栈 | **Flutter** + `receive_sharing_intent` + `super_clipboard` |
| 6 | 抓取 | **C 起步**：URL+元数据必存，正文尽力而为；可插拔抓取器 |
| 7 | 输出 | 直接写 **.md 到 vault** + YAML frontmatter + 默认 `Roosty/` 子目录 |
| 8 | AI | **写入前摘要 Processor**（可插拔）；对话留给 Obsidian 生态 |
| 9 | LLM | 用户自填 **OpenAI 兼容端点**（base_url+key+model），默认示例 DeepSeek |

---

## 3. 技术架构总览

数据单向流，分层清晰：

```
[入口层 Source]                [核心管线 Pipeline]                 [输出层 Sink]
 ┌─────────────┐
 │ 分享菜单     │ ──┐
 │ (Android)   │   │   ┌──────────┐   ┌────────────┐   ┌──────────────┐   ┌─────────────┐
 │ 剪贴板监听   │ ──┼──▶│ Capture  │──▶│  Fetcher   │──▶│  Processor   │──▶│  ObsidianSink│
 │ (Desktop)   │   │   │ 归一化    │   │ 抓取(可插拔)│   │ 摘要(可插拔) │   │  写 .md      │
 │ 手动粘贴页   │ ──┘   └──────────┘   └────────────┘   └──────────────┘   └─────────────┘
 └─────────────┘            │                                                      │
                            ▼                                                      ▼
                     [Item 数据模型]                                        vault/Roosty/*.md
```

**关键抽象（写代码时按接口编程，保证可插拔、不返工）：**

| 抽象 | 职责 | MVP 实现 | 未来扩展 |
|------|------|---------|---------|
| `Source` | 产生原始输入（URL/文本） | ShareIntentSource、ClipboardSource、ManualSource | App 内分享扩展、浏览器扩展 |
| `Item` | 统一数据模型 | url, title, source平台, author, capturedAt, rawText, summary, tags, status | — |
| `Fetcher` | 从 URL 抓取正文+元数据 | WebFetcher（readability 类，普通网页够用） | 微信/小红书/X 专用 Fetcher（走轻后端） |
| `Processor` | 加工 Item | SummarizeProcessor（调 LLM 出摘要+标签） | RAG、任务抽取（如真要做） |
| `Sink` | 输出 Item | ObsidianSink（写 .md） | Notion、本地 JSON、其他 |

**md 文件 schema（每条内容一个文件）：**

```markdown
---
title: "文章标题"
source: wechat          # wechat | x | xiaohongshu | video | web
url: https://...
author: "原作者"
captured: 2026-06-14T12:30:00+08:00
summary: "AI 一句话摘要"     # SummarizeProcessor 回填
tags: [roosty/inbox]
status: unread          # unread | archived
---

# 文章标题

> 来源：微信文章 · [原文链接](https://...)

## 摘要
（AI 摘要正文）

## 原文
（抓到的正文；抓不到则：> ⚠️ 正文未抓取，点击上方链接查看原文）
```

文件名：`YYYY-MM-DD-标题-slug.md`，落在 `<vault>/Roosty/` 下。

---

## 4. 里程碑（Milestones）

按「最快跑通核心闭环 → 再向外扩」的顺序，每个里程碑都是一个可演示、可发布的节点。

### M0 — 项目骨架（地基）
**交付物：** 一个能跑起来的空 Flutter 工程 + 分层目录 + 核心接口定义。
**完成标准：** `flutter run` 在 Windows 上能启动一个空界面；`Source/Item/Fetcher/Processor/Sink` 接口已定义但可为空实现。

### M1 — 桌面闭环（核心魔法首次跑通）★最关键
**交付物：** Windows 端「复制链接 → 自动归巢到 Obsidian」全链路。
**完成标准：** 在浏览器复制一条普通网页 URL → Roosty 剪贴板监听捕获 → WebFetcher 抓到标题+正文 → ObsidianSink 写出一篇 .md → 打开 Obsidian 能看到这篇笔记（带 frontmatter）。**此刻产品已有可发的 demo。**

### M2 — AI 摘要（魔法升级）
**交付物：** SummarizeProcessor 接入，md 里多出 AI 摘要和自动标签。
**完成标准：** 配置 OpenAI 兼容端点后，归巢的 md 的 frontmatter 有 `summary`、`tags` 由 AI 生成；未配置 key 时自动跳过摘要、不报错。

### M3 ⏸ 安卓分享菜单（v1 暂缓，代码冻结保留）
**状态：v1 不交付**；代码已存在于仓库中但未启用，恢复条件见 `DECISIONS.md` §移动端暂缓。
**原计划交付物：** Android 端出现在系统「分享到」菜单，接收 App 分享进来的链接/文本。
**原计划完成标准：** 在手机微信/X/小红书点「分享 → Roosty」，内容进入同一条管线，归巢成 .md（vault 路径用 SAF 授权目录）。

### M4 — 开源发布（抢先达成）★项目目标
**交付物：** 公开 GitHub 仓库 + README + 配置示例 + 一键运行说明 + 演示 GIF。
**完成标准：** 陌生人按 README 能在 30 分钟内跑起来；仓库挂上 roosty.io（或 .dev）。仅交付 Windows 安装包；Android APK 不在 v1 范围。

### M5+（roadmap，不进首发）
- 平台专用 Fetcher（微信/小红书/X 走轻后端）
- iOS Share Extension + macOS
- 浏览器扩展一键剪藏
- 更多 Sink（Notion 等）/ 更多 Processor

---

## 5. 任务节点（Task Breakdown）

> 颗粒度到「可独立完成、可验证」。✅=MVP 必做，⭐=核心路径，🔵=roadmap。

### M0 项目骨架
- [ ] ✅⭐ T0.1 初始化 Flutter 工程（启用 windows + android desktop/mobile target）
- [ ] ✅ T0.2 搭分层目录：`lib/{sources,core,fetchers,processors,sinks,config,ui}`
- [ ] ✅⭐ T0.3 定义核心接口：`Source`、`Item`(数据类)、`Fetcher`、`Processor`、`Sink`
- [ ] ✅ T0.4 引入依赖：`super_clipboard`、`receive_sharing_intent`、`http`、`html`(解析)、`yaml`
- [ ] ✅ T0.5 配置模型 + 本地持久化（vault 路径、LLM 配置）

### M1 桌面闭环 ★
- [ ] ✅⭐ T1.1 `ClipboardSource`：桌面常驻监听剪贴板，识别其中的 URL
- [ ] ✅⭐ T1.2 `WebFetcher`：http 拉取 → readability 式正文/标题/作者提取
- [ ] ✅⭐ T1.3 `ObsidianSink`：渲染 Item → frontmatter + 正文 → 写 .md 到 `<vault>/Roosty/`
- [ ] ✅ T1.4 文件名生成（日期+标题+slug，去非法字符、防重名）
- [ ] ✅ T1.5 Pipeline 串联：Source→Fetcher→Sink，错误兜底（抓取失败仍存链接占位）
- [ ] ✅ T1.6 最简 UI：设置 vault 路径 + 一个「归巢历史」列表 + 手动粘贴框
- [ ] ✅⭐ T1.7 端到端验证：复制真实网页 URL，确认 Obsidian 出现正确 md

### M2 AI 摘要
- [ ] ✅ T2.1 `LlmClient`：OpenAI 兼容 chat/completions 调用（base_url+key+model）
- [ ] ✅⭐ T2.2 `SummarizeProcessor`：正文 → 摘要 + 要点 + 标签（prompt 设计）
- [ ] ✅ T2.3 接进 Pipeline（Fetcher 后、Sink 前），回填 summary/tags
- [ ] ✅ T2.4 未配置 key / 调用失败时优雅降级（跳过摘要，照常归档）
- [ ] ✅ T2.5 设置页：填 base_url/key/model，默认示例 DeepSeek

### M3 ⏸ 安卓分享菜单（v1 暂缓）

> 以下任务在 v1 不交付；代码已冻结保留在仓库中，恢复条件见 `DECISIONS.md`。

- [ ] ⏸ T3.1 `receive_sharing_intent` 接入，注册 intent-filter（接 text/url）
- [ ] ⏸ T3.2 `ShareIntentSource`：分享进来的内容归一化为 Item 喂进同一 Pipeline
- [ ] ⏸ T3.3 安卓 vault 目录：SAF 授权一个目录作为写入根
- [ ] ⏸ T3.4 安卓端到端验证（从真实 App 分享）

### M4 开源发布 ★
- [ ] ✅ T4.1 README（定位/截图/30 分钟上手/配置说明）
- [ ] ✅ T4.2 配置示例文件 + .gitignore（防泄漏 key）
- [ ] ✅ T4.3 演示 GIF / 短视频（核心魔法）
- [ ] ✅ T4.4 LICENSE（建议 MIT）+ 注册 roosty.io/.dev + 建 GitHub 组织
- [ ] ✅ T4.5 打包 Windows 安装包挂 Release（v1 不打 Android APK）

---

## 6. 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| 正文抓取无底洞（微信/小红书反爬） | 拖死 MVP | M1 只保证 URL+元数据必存，正文尽力而为；硬骨头平台延后到 M5 轻后端 |
| 战线过长，被对方抢先 | 失去「抢先」核心目标 | 严守 MVP 边界，M1→M4 一条线打穿即发布，其余全进 roadmap |
| iOS 上架审核拖慢节奏 | 数周延误 | iOS 完全不进首发；v1 移动端整体暂缓 |
| 移动端 vault 沙盒访问受限 | 安卓写入失败 | （v1 不适用，移动端暂缓）安卓恢复时用 SAF 授权目录 |
| 开源用户被 LLM key 滥用 | 成本/安全 | 绝不内置托管 key，强制用户自填 OpenAI 兼容端点 |
| 品牌碰瓷 Sherlockdogs | 舆论攻击 | 只复刻功能，名字/视觉/叙事全部原创（Roosty 与侦探狗零关系）|
| 域名 .com 被占 | 官网受限 | 开源圈认 .io/.dev，已确认可注册，非阻塞 |

---

## 7. 下一步

M0 → M1 是关键路径。建议立即从 **T0.1（初始化 Flutter 工程）** 开始，目标是用最短时间打通 M1 的桌面核心闭环，让产品尽早有可演示的 demo。

> 本文档为后续所有开发的唯一依据；决策变更需回此表更新。
