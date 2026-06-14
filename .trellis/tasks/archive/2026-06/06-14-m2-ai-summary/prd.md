# M2 — AI 摘要（魔法升级）

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根目录 `ROADMAP.md`（第 2 章决策 8/9 + 第 3 章 Processor 抽象）。**
**前置：M1 已完成（Pipeline 跑通，Processor 是 pass-through 空实现）。**

---

## 目标

接入 `SummarizeProcessor`：归巢的 md 里多出 **AI 摘要 + 自动标签**。LLM 用**用户自填的 OpenAI 兼容端点**，未配置时优雅降级（跳过摘要，照常归档，绝不报错）。

## 完成标准（验收）

- 配置好 base_url + key + model 后，归巢的 md 的 frontmatter `summary` 有 AI 摘要、`tags` 含 AI 生成标签，正文「## 摘要」段落被回填。
- 未配置 key / 调用失败时，md 照常生成，只是没摘要，**全程不报错、不阻塞归档**。

## 节点 checklist

- [x] T2.1 `LlmClient`：封装 OpenAI 兼容 `POST {base_url}/chat/completions`（带 `Authorization: Bearer {key}`、model、messages），返回文本
- [x] T2.2 `SummarizeProcessor implements Processor`：输入 Item.rawText → 调 LlmClient → 解析出「一句话摘要 + 3-5 个要点 + 2-4 个标签」→ 回填 `Item.summary` / `Item.tags`。Prompt 要求模型按固定 JSON 结构返回，便于解析
- [x] T2.3 把 SummarizeProcessor 接进 Pipeline（替换 M1 的 pass-through，位置在 Fetcher 后、Sink 前）
- [x] T2.4 降级逻辑：未配置 key → 跳过；调用超时/失败 → catch 后跳过，记一条日志，继续 Sink
- [x] T2.5 设置页：填 base_url / key / model 三件套，默认占位示例填 DeepSeek（`https://api.deepseek.com` / `deepseek-chat`）；key 输入框做成密码态

## 关键约束

- **动工前必读项目根 `DECISIONS.md`。**
- 摘要语言**跟随原文**（中文文章出中文摘要）。
- rawText 为空（M1 没抓到正文）时，不调 LLM（没内容可摘），直接跳过。
- LLM 调用要有超时（30s），避免卡死 Pipeline。
- 标签需加前缀归到 `roosty/` 命名空间下，或追加到默认 `roosty/inbox` 之后。
- key 持久化复用 M0 的配置存储，**绝不硬编码任何 key**。
- 设置页 UI 中文；这是本轮 goal 的最后一个里程碑，完成后桌面完整魔法即达成。

## 完成后

更新 checklist → `task.py finish` → `trellis:continue` 接 M3。
