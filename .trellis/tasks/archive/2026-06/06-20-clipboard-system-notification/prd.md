# 剪贴板归巢走自绘悬浮窗

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根 `ROADMAP.md` + `DECISIONS.md`，及本 prd 列出的所有锁定决策。**
**前置：M0/M1/M2/M3 + auto-discover-vault 已完成。本任务在已有架构上扩展，不改接口签名。**

---

## 背景：为什么做这个

M1 端到端验证后用户反馈：剪贴板捕获 URL 后，必须切到 Roosty 窗口才能点确认归档。这违背了「不打断心流」的核心魔法。

我们调研后**没有走 Windows 原生 toast**（理由：跨端不一致 + 调试体验差 + 美学控制弱），改为**自绘悬浮 mini 窗** —— 借鉴 Raycast / Alfred / uTools 的成熟范式，用 Flutter 桌面的 `window_manager` 起一个无边框、置顶、不抢焦点的小窗，停在右下角。配套**系统托盘图标**做被动反馈（归档完成、状态切换）。

## 目标

复制 URL → 屏幕右下角立刻弹一个 380×200 的 Roosty 自绘 mini 卡片（不切窗口、不抢焦点）→ 卡片渐进式填充：URL → 标题 → 摘要 → 三按钮 `[归巢] [忽略一次] [永不归档此域名]` → 用户决策后卡片滑出消失，后台静默处理，完成时托盘图标轻微闪烁 1 秒。

## 完成标准（端到端实跑）

1. 在浏览器复制一条网页 URL → **Roosty 主窗口不切到前台**，屏幕右下角任务栏上方 16px 处弹出 mini 卡片。
2. 卡片立刻显示：来源平台 icon + URL 截断；几秒内标题填入；摘要随后填入。
3. 点 **[归巢]** → 卡片 200ms 滑出 + 淡出 → 完成后托盘图标闪烁 1 秒 → 去 vault 看到新 .md。
4. 点 **[忽略一次]** → 卡片消失；30 分钟内复制**同一条 URL** 不再弹卡片（后台仍能识别，只是不打扰）。
5. 点 **[永不归档此域名]** → 卡片消失 + 该域名加入持久化黑名单；之后复制该域名下任何 URL 不再弹。
6. 连续复制多条不同 URL → 最多叠 3 张卡片（向上堆）；超过 3 张时最早那张自动按「忽略一次」处理消失。
7. 设置页有「忽略列表」面板，可逐条查看/移除黑名单域名。

---

## 锁定决策（不可改，已与用户敲定）

### 1. 形态：自绘悬浮窗 + 托盘图标（不用系统 toast）
- 主交互：`window_manager` 起无边框置顶不抢焦点的 mini 窗
- 被动反馈：系统托盘图标 + 右键菜单 + 归档完成闪烁

### 2. 窗口规格
- **位置**：屏幕**右下角**，任务栏上方 16px
- **尺寸**：宽 380px × 高 200px
- **属性**：`alwaysOnTop: true`、`focusable: false`、`skipTaskbar: true`、无边框
- **多张叠加**：向上堆，最多同时 3 张；超过即按「忽略一次」剔除最早那张
- **关闭动画**：200ms 滑出 + 淡出

### 3. 内容密度（对友重密度）
卡片从上到下展示：
- 来源平台 icon（wechat / x / xiaohongshu / video / web）+「Roosty 看到一条链接」
- 抓取的**标题**（一行截断）
- URL 截断（一行）
- AI 摘要预览（最多 2 行截断）
- 三按钮横排：`[归巢] [忽略一次] [永不归档此域名]`

### 4. 时机：复制即弹 + 渐进式填充
- 复制后**立刻弹空壳卡片**，避免「等了 5 秒没反应」的认知缺失
- URL 0ms 出，标题等 Fetcher 1-3s 出，摘要等 LLM 3-10s 出
- 各字段加载中显示 skeleton placeholder（淡灰色块）

### 5. 「归巢」按钮：摘要未到时也能点
- 卡片立刻关闭，后台**继续**抓取 + 摘要 + 写 md
- 完成时托盘图标闪烁 1 秒（不弹气泡，不打扰）
- 失败时托盘图标变红 + tooltip 提示，用户可以点托盘看详情

### 6. 「忽略一次」：URL 级 30 分钟静默
- 内存维护一个 `Map<String, DateTime>`：URL → 忽略时间戳
- 30 分钟内复制同 URL 不再弹卡片（后台仍捕获，但不显示）
- **不持久化**到磁盘（重启即清，避免「我都不记得拒绝过这个」的反作用）
- TTL 到期自动清理

### 7. 「永不归档此域名」：持久化黑名单
- 持久化到 `shared_preferences` 新字段 `flutter.domainBlocklist`（List<String>）
- 提取 URL 的域名（如 `mp.weixin.qq.com`、`twitter.com`），整域匹配
- 加入黑名单后该域名下**任何 URL** 都不再弹卡片
- 设置页提供「忽略列表」UI，列出全部黑名单域名 + 每条「移除」按钮

### 8. 系统托盘图标
- App 启动时注册托盘图标（用 `tray_manager` pub 包）
- 右键菜单：`[打开 Roosty]` `[暂停剪贴板监听]` `[退出]`
- 状态反馈：归档成功闪烁 1 秒；失败时红点 + tooltip
- 双击托盘 = 打开主窗口

---

## 节点 checklist

- [x] T1 引入依赖：`window_manager`（已有 4.x） + `tray_manager`（最新稳定版），`flutter pub get` 通过
- [x] T2 设计 `MiniCardWindow` 组件（独立 widget tree，单独的 main entry 或 ProviderScope override）
  - 380×200 无边框，alwaysOnTop，不抢焦点
  - 渐进式 skeleton 加载状态
  - 三按钮 + 关闭滑出动画
- [x] T3 实现 `MiniCardWindowManager` 服务：
  - 调用 `window_manager` 创建/定位/堆叠多窗
  - 维护 active windows 列表（最多 3 张），溢出剔除策略
- [x] T4 重写 `ClipboardSource` 的捕获后行为：
  - 不再走应用内卡片，改为通过 `MiniCardWindowManager` 弹出 mini 窗
  - URL 立刻弹，Fetcher/Processor 完成时通过 stream 更新卡片状态
- [x] T5 实现「忽略一次」内存 Map + 30 分钟 TTL 清理（Riverpod provider）
- [x] T6 实现域名黑名单：
  - 持久化到 `shared_preferences.flutter.domainBlocklist`
  - URL → 域名提取工具函数
  - 命中黑名单时直接 skip 弹卡片
- [x] T7 实现「忽略列表」UI（设置页新增一节）：列表展示 + 单条移除
- [x] T8 实现系统托盘：`tray_manager` 注册 + 右键菜单 + 归档闪烁反馈
- [x] T9 单元测试：① 域名提取（含 IDN/端口边界） ② 30 分钟 TTL 过期 ③ 黑名单持久化 ④ 多窗口溢出策略 ⑤ Mini 窗渐进式状态机
- [x] T10 端到端实跑：复制 URL → 看到右下角卡片 → 等填充 → 三按钮各自验证 → 连续复制 4 条验证溢出 → 黑名单/忽略列表 UI 验证

---

## 关键约束

- **不改 M0 五接口签名**（`Source/Item/Fetcher/Processor/Sink`）。`ClipboardSource` 内部行为变（弹卡片方式），但接口契约不变。
- **不破坏现有应用内卡片场景**（手动粘贴、首启 vault 卡片仍走主窗口）。Mini 窗只是剪贴板捕获的新呈现层。
- App UI 中文，代码注释/标识符英文。
- **不引入新存储概念**：黑名单复用 `shared_preferences`；忽略 Map 仅内存；接口契约不变。
- LLM key 暴露风险**不变**（已 .gitignore 防）。
- 托盘归档完成的「闪烁 1 秒」**不弹气泡**，避免和「不打扰」哲学矛盾。
- Mac/Linux 在本任务**保留主窗卡片旧行为**（mini 窗 + 托盘只在 Windows 实现），代码里留 platform 分支 + TODO。

---

## 范围外（roadmap，本任务不做）

- 自定义弹窗模板系统（用户改卡片内容/布局）
- iOS / Android 上的等价交互（移动端走分享菜单，路径不同）
- 多语言通知文案（中文写死，i18n 后续）
- 通知声音 / 振动
- 卡片内编辑标签 / 改标题 后再归档
- macOS / Linux 自绘悬浮窗（先记 TODO）

## 完成后

更新 checklist → `task.py finish`。下一个任务：UI 视觉重做（兄弟任务 `06-20-ui-visual-redesign`），可在本任务后单独 brainstorm。

## 当前实现记录（2026-06-20）

- 已完成：依赖引入、`desktop_multi_window` 独立子窗口、Windows 剪贴板捕获改走 mini card 状态机、URL 级 30 分钟忽略、域名黑名单持久化、设置页忽略列表、托盘桥接、单元/Widget 测试覆盖。
- 当前实现：主窗口持有 pipeline/state；mini 子窗口是独立 Flutter engine，只显示序列化后的卡片状态，并通过 `WindowMethodChannel` 回传「归巢 / 忽略一次 / 永不归档」动作；子窗口用 Win32 `WS_EX_NOACTIVATE` / `WS_EX_TOOLWINDOW` / `WS_EX_TOPMOST` 样式配合 `show(inactive: true)` 降低抢焦点风险。
- 已完成 T10 端到端实跑：Release exe + 本地 HTTP/LLM 假服务 + 临时 shared_preferences/vault，验证右下角独立 mini 窗、`WS_EX_NOACTIVATE`/`WS_EX_TOOLWINDOW`/`WS_EX_TOPMOST` 样式、忽略一次、域名黑名单持久化、归档写入 markdown、连续 4 条最多 3 张窗口；忽略列表 UI 由 widget 测试覆盖。
- 验证：`flutter analyze`、`flutter test`（43 项）、`flutter build windows`、Release E2E 通过。
