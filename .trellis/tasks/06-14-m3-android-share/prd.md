# M3 — 安卓分享菜单（第二条腿）

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根目录 `ROADMAP.md`（第 2 章决策 3/4 + 第 3 章 Source 抽象）。**
**前置：M1 已完成（Pipeline 跑通）、M2 已完成（摘要可选接入）。**

---

## 目标

让 Roosty 出现在 Android 系统「分享到」菜单里，接收从微信/X/小红书/视频/浏览器分享进来的链接或文本，喂进**同一条 Pipeline**，归巢成 .md。

## 完成标准（验收 — 端到端，真机或模拟器）

在手机某个 App（微信文章/X/小红书/浏览器）点「分享 → Roosty」→ Roosty 接收到链接/文本 → 进入与桌面相同的 Source→Fetcher→Processor→Sink 管线 → 在 SAF 授权的 vault 目录里生成 .md。

## 节点 checklist

- [x] T3.1 `receive_sharing_intent` 接入：配置 Android `AndroidManifest.xml` 的 intent-filter，接收 `text/plain`（含 URL）和分享的文本；冷启动 + 热启动两种分享场景都要处理
- [x] T3.2 `ShareIntentSource implements Source`：把分享进来的 text/url 归一化成 Item（提取其中 URL，识别 source 平台），喂进同一 Pipeline
- [x] T3.3 安卓 vault 目录：用 SAF（Storage Access Framework）让用户授权一个目录作为写入根，持久化授权 URI；ObsidianSink 在安卓上通过 SAF 写文件（桌面仍用直接文件写，做平台分支）
- [x] T3.4 安卓端到端验证：从真实 App 分享，确认归巢成功（必须实跑）

## 关键约束

- **动工前必读项目根 `DECISIONS.md`（尤其「两端触发模型」一节）。**
- **移动端只做「系统分享菜单接收」这一条腿，绝不做后台剪贴板监听**（Android 10+ 后台读不到剪贴板，且国内 App 乱塞链接信噪比极低）。
- **分享进来 = 用户主动表意图 → 静默归档，不弹确认、不打断**（区别于桌面剪贴板的「弹确认」）。
- 「打开 App 时读一次剪贴板」作为可选功能（前台主动 + 弹确认），优先级低，可放到 checklist 最后或留待后续。
- **复用桌面已有的 Fetcher/Processor/Sink 逻辑**，只新增 Source 实现和平台相关的文件写入分支，不要另起一套管线。
- 安卓文件写入受沙盒限制，**必须走 SAF 授权目录**，不能假设能直接写任意路径。
- source 平台识别：从分享文本里的 URL 域名判断（mp.weixin.qq.com→wechat、x.com/twitter→x、xiaohongshu→xiaohongshu 等），识别不出归 web。
- iOS 不在本里程碑范围（进 roadmap）。

## 完成后

更新 checklist → `task.py finish` → `trellis:continue` 接 M4。
