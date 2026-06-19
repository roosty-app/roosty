# Auto-discover Obsidian Vault

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根 `ROADMAP.md` + `DECISIONS.md`，及本 prd 列出的所有锁定决策。**
**前置：M0/M1/M2/M3 已完成。本任务在已有架构上扩展，不改接口签名。**

---

## 背景：为什么做这个

M1 端到端验证时暴露了一个体验问题：用户「随手填」vault 路径（如 `Desktop\tmp`）→ Roosty 老老实实把 md 写到那里 → 但用户 Obsidian 实际打开的是 `D:\...\Obsidian Vault`，导致「文章丢了」的错觉。

事实是 Obsidian 把所有 vault 列表存在固定位置（Windows 是 `%APPDATA%\obsidian\obsidian.json`），Roosty 完全可以读出来引导用户一键确认，而不是让用户自己输路径——这是同类产品的基础体验。

## 目标

首启自动检测用户已有的 Obsidian vault 列表，弹卡片让用户一键确认正确的归档库，让「Roosty 写到的 = Obsidian 看到的」零思考成立。

## 完成标准（端到端验收，必须实跑）

新装/无配置的 Roosty 在 Windows 上启动 → 卡片自动列出 Obsidian 的 vault → 点「使用此库」→ 关掉 app 再开**不再弹卡片** → 在 Obsidian 库下能看到刚建好的空 `Roosty/` 子目录 → 复制一条 URL 走完整 M1 闭环 → md 归到那个 `Roosty/`，Obsidian 立刻能看到。**这一整条跑通才算完成。**

---

## 锁定决策（不可改，已与用户敲定）

### 1. 首启 UX
- **首次启动**（`vaultPath` 为空）弹卡片，**已设过 vault 的不打扰**。
- **单 vault 时**：大按钮「使用 `<完整路径>`」+ 小字「选其他目录」。
- **多 vault 时**：列表 radio，**`open=true` 排第一并默认勾选**，其余按 `ts` 倒序；列表显示**目录路径**（不是 vault 名）。
- **未检测到 / 没装 Obsidian**：降级显示「未检测到 Obsidian。请选择一个目录作为归档库 →」+ 文件选择器入口。
- 设置页加按钮「重新检测 Obsidian 库」，用户换 vault 时手动触发，重弹卡片。

### 2. 默认归档子目录
- 写死 `<vault>/Roosty/`，**首启不让用户改**（高级选项可后续放设置页，本任务不做）。

### 3. 平台范围
- **必做**：Windows、Android。
- **Mac / Linux**：返回空列表降级（走「未检测到」路径），代码里留 TODO + 注释官方注册表路径，方便后续 PR。
- **Android**：先调研 `obsidian.json` 在 Android 上的位置/可读性，调研结果写入 `{task_dir}/research/`。**若不可读则保留现状（手动选 SAF 目录）**，不强行做。

### 4. 实现要点
- **新增 `VaultDiscovery` 服务**（独立类，不塞进 `ConfigRepository`），职责：扫平台 → 解析注册表 → 返回候选列表。
- UI 通过 Riverpod provider 拿候选列表，与已有架构一致。
- 持久化复用现有 `vaultPath` 字段，不引入新存储。
- **选定 vault 后立即在其下建空 `Roosty/`**，让用户首启就有「连接成功」的视觉确认；建立失败要明确报错（权限/磁盘等），不静默吞。

### 5. 失败处理（统一返回空列表，不抛异常）
- `obsidian.json` 不存在
- JSON 解析失败
- 路径里的 vault 实际目录已删
- 权限不足读不到
- 写日志方便 debug，不打扰用户。

---

## 节点 checklist（做完一个勾一个）

- [x] T1 调研 Android 上 Obsidian `obsidian.json` 位置/可读性，写入 `research/android-obsidian-discovery.md`，定结论：可读 / 不可读
- [x] T2 实现 `VaultDiscovery` 服务（Windows 解析 `%APPDATA%\obsidian\obsidian.json` + 候选排序 + 失败统一返空 + Mac/Linux placeholder + Android 按 T1 结论实现或降级）
- [x] T3 Riverpod provider 暴露候选 vault 列表
- [x] T4 首启卡片 UX：单 vault 一键 / 多 vault 列表 / 检测不到降级 + 文件选择器兜底
- [x] T5 选定 vault 后立即建 `<vault>/Roosty/` 空目录，建失败明确报错
- [x] T6 设置页「重新检测 Obsidian 库」按钮，重弹卡片
- [x] T7 单元测试：① mock `obsidian.json`：单/多/损坏/不存在 4 用例 ② 排序逻辑 ③ 持久化（选完再启不弹）④ 未知平台返空降级
- [x] T8 端到端实跑：清空 `vaultPath` → 启动 → 卡片出现 → 选库 → 看到空 `Roosty/` → 关再开不弹 → 复制 URL → md 归档到位

## 关键约束

- 不改 M0 定义的 5 接口签名（`Source/Item/Fetcher/Processor/Sink`）；本任务在配置/UI 层加东西。
- App UI 中文，代码注释/标识符英文（与 DECISIONS.md 一致）。
- 加密钥/隐私无关——这个任务不碰 LLM key 或归档逻辑，纯 UX + 配置层。
- T1 的 Android 调研是 GO/NO-GO 决策点：不可读则 T2 的 Android 部分降级，不强行做。

## 完成后

更新 checklist → `task.py finish`。这是一个**用户体验**任务而非里程碑，完成后回到 M4 主线（开源发布）。
