# M4 — 开源发布（抢先达成，v1 桌面优先）★项目目标

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根目录 `ROADMAP.md`（第 1 章目标 + 第 6 章风险） + `DECISIONS.md` §移动端暂缓决策记录。**
**前置：M1（桌面闭环）必须完成；M2 完成更好，但只要 M1 能 demo 即可发首版。M3（Android）已暂缓，v1 不交付。**

---

## 目标

把 Roosty 做成陌生人能在 30 分钟内 `git clone` 跑起来的开源项目，抢在对方（Sherlockdogs）发布前公开传播。**v1 仅交付桌面（Windows）端**。

## 完成标准（验收）

- 陌生人按 README 能在 30 分钟内跑起桌面端核心闭环。
- 仓库有清晰定位、截图、配置说明、LICENSE。
- **Windows 安装包**挂在 Release。Android APK **不在 v1 范围**（移动端代码已冻结保留，恢复条件见 `DECISIONS.md`）。

## 节点 checklist

- [ ] T4.1 README：定位（一句话魔法）、核心截图/GIF、30 分钟上手步骤、vault 配置说明、LLM 配置说明、roadmap（恢复 Android / iOS / 浏览器扩展 / 平台专用抓取）
- [ ] T4.2 配置示例文件（`config.example` 之类）+ `.gitignore`（**确保任何含 key 的本地配置不进仓库**）
- [ ] T4.3 演示 GIF / 短视频：录核心魔法「复制链接 → 几秒后 Obsidian 出现带摘要的笔记」（**桌面端录制**）
- [ ] T4.4 LICENSE（MIT）+ 建 GitHub 组织（`roosty-io` / `roostyhq`，因 `roosty` 用户名已被占）。自定义域名 `roosty.io` 暂缓（成本考虑，不阻塞首发；先用 GitHub 仓库 URL）
- [ ] T4.5 打包：**Windows 安装包**（`flutter build windows`）挂 GitHub Release。Android APK 暂缓，等恢复 Android 端时再补。

## 关键约束（品牌安全 — 来自 ROADMAP 风险表）

- **全程不出现「Sherlockdogs / 侦探 / 狗 / 华生 / 线索」任何字样和视觉**。Roosty 的叙事只用「归巢 / roost / 鸟 / 巢」。
- 名字、logo、文案、截图全部原创，与对方零关系，杜绝碰瓷口实。
- README 里强调：独立实现、开源、品牌完全不同。

## 域名/命名既定事实（来自规划阶段查证）

- 可注册：`roosty.io` / `.dev` / `.ai` / `.co`（`.com/.app/.org/.xyz` 已被占）
- pub.dev / npm 包名 `roosty` 空闲可用
- GitHub 用户名 `roosty` 已占 → 用组织名 `roosty-io` 或 `roostyhq`

## 完成后

更新 checklist → `task.py finish`。项目核心目标（抢先开源 v1 桌面端）达成。
