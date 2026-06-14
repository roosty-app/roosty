# M1 — 桌面闭环（核心魔法首次跑通）★最关键里程碑

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根目录 `ROADMAP.md`，动工前必读第 3 章（架构 + md schema）。**
**前置：M0 已完成（接口已定义）。若 `lib/` 下无接口文件，先回头确认 M0。**

---

## 目标

打通 Windows 端完整链路：**复制一条网页 URL → 自动抓取 → 写出一篇 .md 到 Obsidian vault**。这是整个产品的核心魔法，做完即有可发布的 demo。

## 完成标准（验收 — 端到端）

在浏览器复制一条**真实网页 URL** → Roosty 剪贴板监听捕获 → WebFetcher 抓到标题+正文 → ObsidianSink 写出 `.md` → 用文本编辑器/Obsidian 打开 `<vault>/Roosty/` 能看到这篇笔记，frontmatter 和正文正确。抓取失败时也要落一篇「只有链接+标题占位」的 md，不能丢内容。

## 节点 checklist（做完一个勾一个）

- [x] T1.1 `ClipboardSource implements Source`：桌面常驻轮询/监听剪贴板，用正则识别其中的 URL，去重（同一 URL 短时间内不重复触发）。**捕获到 URL 后不静默归档，而是弹通知/应用内提示让用户确认，用户点确认才产出 Item 进管线**（兼顾魔法感与隐私，见 DECISIONS.md）
- [x] T1.2 `WebFetcher implements Fetcher`：`http` 拉取 HTML → 用 `html` 包做 readability 式提取（取 `<title>`、`<article>`/正文、`og:` 元数据、author）。`canHandle` 对普通 http(s) 返回 true
- [x] T1.3 `ObsidianSink implements Sink`：把 Item 渲染成 frontmatter + 正文（**严格按 ROADMAP 第 3 章的 md schema**），写 `.md` 到 `<vault>/Roosty/`
- [x] T1.4 文件名生成：`YYYY-MM-DD-标题-slug.md`，去 Windows 非法字符（`\ / : * ? " < > |`），重名加序号
- [x] T1.5 Pipeline 串联：`Source → Fetcher → Processor(M1 阶段为空 pass-through) → Sink`，每段 try/catch，抓取失败仍写占位 md（正文写「⚠️ 正文未抓取，点击上方链接查看原文」）
- [x] T1.6 最简 UI：① 设置 vault 路径（目录选择器）② 「归巢历史」列表（显示已归档的 Item）③ 手动粘贴框（粘 URL 手动触发，便于测试）
- [x] T1.7 端到端验证：Windows GUI 已实跑 `https://example.com`：剪贴板捕获后显示待确认卡片，点击确认后 `<temp-vault>/Roosty/2026-06-14-Example-Domain.md` 写出，frontmatter、URL、标题、正文均验证通过。

## md schema（T1.3 严格遵守，与 ROADMAP 第 3 章一致）

```markdown
---
title: "文章标题"
source: web
url: https://...
author: "原作者"
captured: 2026-06-14T12:30:00+08:00
summary: ""
tags: [roosty/inbox]
status: unread
---

# 文章标题

> 来源：网页 · [原文链接](https://...)

## 摘要
（M1 阶段留空，M2 回填）

## 原文
（抓到的正文；抓不到则：> ⚠️ 正文未抓取，点击上方链接查看原文）
```

## 关键约束

- **动工前必读项目根 `DECISIONS.md`。**
- **M1 不碰 AI**，Processor 阶段先放一个 pass-through 空实现，给 M2 留接口。
- 剪贴板监听**默认关闭**，首启引导用户设 vault + 选择是否开启；捕获走「弹确认再归档」流程（不静默自动归档）。
- **状态管理 Riverpod**：管线状态、归巢历史、vault 配置均用 provider。
- 写文件用绝对路径，vault 路径从 M0 的配置持久化里读。
- App UI 中文，代码注释/标识符英文。

## 完成后

更新 checklist → `task.py finish` → 此刻**产品已有可发 demo**，可截图存档 → 下一对话 `trellis:continue` 接 M2。
