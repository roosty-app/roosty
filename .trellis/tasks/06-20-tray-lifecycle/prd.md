# Tray 常驻 + 窗口生命周期

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根 `ROADMAP.md` + `DECISIONS.md`，及本 prd 列出的所有锁定决策。**
**前置：M0/M1/M2/M3 + auto-discover-vault + clipboard-system-notification 已完成。**
**🚨 本任务为实现型任务，不是规划型——必须按 checklist 写代码 + 测试 + 实跑后才能 finish-work，不可只更新文档归档。**

---

## 背景：为什么做这个

clipboard-system-notification 任务自动化测试全过、checklist 全勾、自归档。但用户实跑发现：

1. **托盘图标显示正常，但左单击/左双击/右键全部无响应** → T8「右键菜单 + 反馈」运行时不工作
2. **关闭主窗口 X 按钮直接退出整个进程**（包含剪贴板监听 + tray + 后台 watcher） → prd 没明确写但与「常驻后台工具」定位矛盾
3. **最小化保留在 Windows 任务栏，没有缩到托盘** → 用户期待常驻工具该有的「藏起来不打扰」体验

事实证据：
- `find test -iname "*tray*"` 空，`grep trayManager test/` 空 → **Codex 写了 174 行 tray 代码，零测试覆盖**，T9 第⑤项「Mini 窗渐进式状态机」并不覆盖 tray
- `grep WindowListener\|onWindowClose\|preventClose lib/` 空 → **整个工程没有窗口生命周期监听**

## 目标

让 Roosty 真正成为「常驻后台、托盘守候、用户操作即响应」的桌面工具：
1. 托盘点击（左单击/左双击/右键）100% 响应，菜单项点了真有动作
2. 关闭/最小化主窗口 → 隐藏到托盘，进程继续跑（剪贴板监听不停）
3. 真正退出只走「托盘右键 → 退出」或「设置页 → 退出 Roosty」

## 完成标准（端到端实跑，必须真验证不是单测过就算数）

1. 托盘图标存在 → 单击左键 → 主窗口显示+获取焦点
2. 双击左键 → 同上
3. 右键 → 弹出菜单 [打开 Roosty / 暂停剪贴板监听 (或 恢复剪贴板监听) / 分隔线 / 退出]
4. 点「打开 Roosty」→ 主窗口显示
5. 点「暂停剪贴板监听」→ 监听关闭，菜单项标签变成「恢复剪贴板监听」（即时反映状态）
6. 点「退出」→ 进程真正退出
7. **完成一次归档**（复制 URL → mini 卡片 → 点归巢）→ 托盘图标 1 秒内有视觉反馈（title 变 ✓ 或 tooltip 闪烁）
8. 主窗口点 X → 不退出，窗口隐藏；任务栏不再显示 Roosty 窗口图标；托盘图标仍在
9. 主窗口点最小化 _ → 同 X，隐藏到托盘
10. 首次隐藏后，托盘图标 tooltip 出现一行「Roosty 已隐藏到托盘」之类的文案（不强制弹气泡，避免打扰），tooltip 至少持续 5 秒可被用户看到
11. 隐藏后剪贴板监听仍工作（验证：复制 URL，mini 卡片仍能弹出来）

---

## 锁定决策（不可改，已与用户敲定）

### 1. X / 最小化都隐藏到托盘
- 监听 `windowManager` 的 `onWindowClose` → 阻止默认退出 → 调 `windowManager.hide()`
- 监听 `onWindowMinimize` → 调 `windowManager.hide()`
- **必须 `windowManager.setPreventClose(true)`** 才能拦到 onWindowClose

### 2. 唯一退出入口
- 托盘右键菜单的「退出」（已存在的 `_exitApp()` 方法保留）
- 设置页加一个「退出 Roosty」按钮，调用同一个 `_exitApp()`
- **不再保留**「窗口被关闭即退出」的默认行为

### 3. 托盘点击 bug 根因 hypothesis（Codex 修复时必须验证）
**假设**：`tray_manager.setIcon()` 在 `initState` 内被同步调用，可能早于 native 侧的 tray ready，导致后续 `addListener` 注册的回调实际未生效。

**修复方向**（Codex 必须按此调研 + 实现）：
- 把 `_initTray()` 的调用从 `initState` 改到 `WidgetsBinding.instance.addPostFrameCallback` 内执行（确保第一帧渲染完再初始化 tray）
- 或者按 `tray_manager` 官方推荐方式：在 `main()` 里 `await trayManager.destroy()` 后再走 widget tree（如果文档要求 main 级初始化）
- **必须验证假设**：调研 `tray_manager` pub.dev 官方 README + GitHub issues，找到「setIcon 必须在哪个时机调」的权威答案，结论写进 `research/tray-init-timing.md`
- 若假设不成立，找出真实根因（可能是 Windows specific 的 plugin registrant 问题、或 mini 卡片 standalone window 抢了 listener，或 desktop_multi_window 与 tray_manager 冲突）

### 4. 测试要求（防止再次形而上学勾选）
**最关键约束**：本任务的测试**不允许只 mock trayManager 让单测过**。必须：
- 加 widget integration test，启动真实 widget tree，验证 `DesktopTrayBridge` 的 listener 在 `onTrayIconMouseUp/onTrayIconRightMouseUp` 触发时**确实调用**了 `_showMainWindow / popUpContextMenu`（用 mock platform channel 拦截调用，断言被调）
- 加 widget integration test 验证 `onWindowClose` 触发时 `windowManager.hide()` 被调（不是 `windowManager.destroy()`）
- 加 widget integration test 验证 `onWindowMinimize` 触发时 `windowManager.hide()` 被调
- **不接受**「只测了 menu 数据结构」「只测了字符串文案」这种擦边球
- T8 必须**亲手实跑**，跑通才能 task.py finish

---

## 节点 checklist

- [x] T1 调研 `tray_manager` 官方推荐初始化时机，写入 `research/tray-init-timing.md`
- [x] T2 修复 tray 点击响应 bug：按 T1 调研结论调整 `DesktopTrayBridge` 的 init 时机
- [x] T3 实现 X 关闭拦截：`main.dart` 加 `await windowManager.setPreventClose(true)`；`HomeScreen` 或独立 `WindowListener` 监听 `onWindowClose` → 调 `windowManager.hide()`
- [x] T4 实现最小化拦截：监听 `onWindowMinimize` → 调 `windowManager.hide()`
- [x] T5 首次隐藏 toast/tooltip 提示（tooltip 设为「Roosty 已隐藏到托盘，点托盘图标恢复」5 秒后恢复默认 tooltip）
- [x] T6 设置页加「退出 Roosty」按钮（红色文本，点了 confirm 一次再退出）
- [x] T7 widget integration test：tray listener 三事件（左单/左双/右键）触发后真的调用了对应方法
- [x] T8 widget integration test：onWindowClose 调 hide 不是 destroy；onWindowMinimize 调 hide
- [x] T9 端到端实跑（按上面 11 项验收清单逐条验证，必须真的点 + 看 + 复制 URL）
- [x] T10 trellis-update-spec：把「常驻桌面 app 必须监听 windowClose/Minimize 拦截默认行为」沉淀进 frontend spec

## 关键约束

- **不改 M0 五接口签名**（`Source/Item/Fetcher/Processor/Sink`）
- **不破坏 mini 卡片功能**（剪贴板捕获 → 弹卡片 → 归巢/忽略/拉黑 链路必须仍通）
- **退出按钮不能误触**：设置页的「退出 Roosty」必须 confirm dialog 二次确认
- **暂停剪贴板监听**：菜单项点了之后状态要持久化到 `shared_preferences` 还是仅会话内？锁定为：**会话内**（重启 Roosty 默认恢复用户上次的 `clipboardWatchingEnabled` 配置，不被托盘点击覆盖）
- App UI 中文，代码注释/标识符英文
- macOS / Linux 走相同 windowManager API（行为一致），托盘部分 platform 分支保留现有 Windows-only

## 完成后

更新 checklist → trellis-update-spec → 主 session 驱动 commit → `/trellis:finish-work`。**T9 实跑必须由用户亲手验证 11 项后告知 GO，否则不许 finish-work。**

## 当前实现记录（2026-06-20）

- 已完成：`tray_manager` 初始化/事件调研、Windows tray click 回调修复、X/最小化隐藏到托盘、首次隐藏 tooltip、设置页二次确认退出、托盘菜单暂停/恢复改为会话内状态、widget integration tests。
- 根因：`tray_manager 0.5.3` Windows 原生层把 `WM_LBUTTONUP` / `WM_RBUTTONUP` 分别派发为 Dart `onTrayIconMouseDown` / `onTrayIconRightMouseDown`；旧实现只监听 `MouseUp`，所以实机点击无响应。
- 用户实测反馈：托盘菜单暂停剪贴板监听后，设置页开关没有同步变化。已修复为设置页读取 `effectiveClipboardWatchingProvider`，托盘暂停仍只改会话内 override、不写入持久化配置；`desktop_lifecycle_test.dart` 覆盖该同步。
- 验证：`flutter analyze`、`flutter test`（46 项）、`flutter build windows` 通过；Release smoke 通过（真实 exe 收到 `WM_CLOSE` / `SC_MINIMIZE` 后进程保持运行，主窗口隐藏）。
- 用户实跑：T9 11 项验收经用户确认通过（2026-06-20 回复 OK）。
- Spec：已在 `.trellis/spec/frontend/desktop-capture-pipeline.md` 增加 `Desktop Tray And Window Lifecycle` 场景。
