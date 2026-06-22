# Journal - cfy (Part 1)

> AI development session journal
> Started: 2026-06-14

---



## Session 1: M0 项目骨架

**Date**: 2026-06-14
**Task**: M0 项目骨架
**Branch**: `master`

### Summary

Initialized the Roosty Flutter skeleton for Windows and Android, defined the core pipeline contracts, added Riverpod/shared_preferences config wiring, updated frontend specs, and verified analyze/test/windows build.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `279351d` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 2: M1 desktop capture loop

**Date**: 2026-06-14
**Task**: M1 desktop capture loop
**Branch**: `master`

### Summary

Implemented and verified the Windows desktop capture loop: clipboard confirmation, web fetch, pass-through processor, Obsidian markdown sink, UI wiring, tests, Windows build, and GUI end-to-end validation.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `2234863` | (see git log) |
| `d8fa76b` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 3: M2 AI summary

**Date**: 2026-06-14
**Task**: M2 AI summary
**Branch**: `master`

### Summary

Implemented OpenAI-compatible AI summary processing, settings UI, markdown summary/tag output, graceful fallback tests, and recorded the processor contract.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `067a4a3` | (see git log) |
| `82126bf` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 4: M3 Android share capture

**Date**: 2026-06-14
**Task**: M3 Android share capture
**Branch**: `master`

### Summary

Implemented Android system share capture for text URLs, added SAF vault writing, documented the capture contract, and verified Flutter checks plus emulator share-to-markdown end to end.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `75e6205` | (see git log) |
| `d0761e9` | (see git log) |
| `a0876fa` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 5: Vault auto-discovery + C drive cache offload

**Date**: 2026-06-20
**Task**: Vault auto-discovery + C drive cache offload
**Branch**: `master`

### Summary

实现 Obsidian vault 自动发现首启卡片 (VaultDiscovery 服务 + Riverpod provider + 立建 Roosty 子目录),根治 M1 暴露的随手填路径体验问题。Codex 完成 T1-T7,主 session 验证 T8 端到端实跑通过 (Roosty 自动检测到 D:\用户目录\我的文档\Obsidian Vault,卡片单 vault 一键体验,Roosty/ 子目录 7 秒内创建)。trellis-check GO。途中 C 盘空间被构建吃爆 (3.1 GB 剩),把 RUSTUP_HOME / CARGO_HOME / PUB_CACHE 永久重定向到 E:\Temp,释放约 3 GB,纯英文路径下 cargokit Rust 编译正常。flutter analyze 零问题, 32 测试全过 (新增 6 个 vault 用例)。

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `dfebf51` | (see git log) |
| `fce1e5f` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 6: Add UX overhaul task plans

**Date**: 2026-06-20
**Task**: Add UX overhaul task plans
**Branch**: `master`

### Summary

Added Trellis planning artifacts for the UX overhaul parent task and its clipboard notification / UI redesign children, then archived the clipboard notification task per finish-work.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `f1185a1` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 7: Windows clipboard mini capture windows

**Date**: 2026-06-20
**Task**: Windows clipboard mini capture windows
**Branch**: `master`

### Summary

Implemented Windows clipboard mini-card capture with independent no-activate child windows, tray feedback, ignore-once/domain blocklist flows, settings UI, tests, spec updates, and Release E2E verification.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `77e024b` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 8: Tray lifecycle and resident window behavior

**Date**: 2026-06-20
**Task**: Tray lifecycle and resident window behavior
**Branch**: `master`

### Summary

Fixed tray mouse handling, resident close/minimize behavior, session-only clipboard pause state sync, desktop lifecycle tests, and recorded tray-manager Windows event research.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `b2e7382` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 9: UI visual redesign + token visual-validation lessons

**Date**: 2026-06-20
**Task**: UI visual redesign + token visual-validation lessons
**Branch**: `master`

### Summary

把 Roosty 从 Material 默认模板升级到温暖手作调性 (米白底 + 暑褐主色 + 思源宋体/Lora 衬线字 + 双主题)。Codex 完成 T1-T9 + T11 (token 系统、字体子集化 5.4MB、双主题、widget 测试 49 项,WCAG AA 全过)。主 session 实跑发现 2 处视觉 bug 直接修: ① onPrimary 从深棕改米白 (按钮文字从融底色变清晰) ② IconButton iconColor 从 primary 改 textPrimary (图标默认就清晰,不用 hover 才看见)。trellis-update-spec 把 3 类 design token 反例追加到 frontend/design-tokens.md (onPrimary 不能继承文本色系统、IconButton 不用品牌色做默认、整套主题应单色温)。flutter analyze + 49 测试全过,build windows 成功。APK 构建因 C 盘空间不足挂在 mergeDebugNativeLibs 阶段 (Android JNI jar 解压报磁盘不足),后续单独处理。UX overhaul 父任务 3 子任务全完成。

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `de5cc40` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 10: drop mobile scope (deferred) + plan brand visual reframe

**Date**: 2026-06-22
**Task**: drop mobile scope (deferred) + plan brand visual reframe
**Branch**: `master`

### Summary

确定 v1 桌面优先：把 Android 端从 v1 scope 暂缓（不删除），代码加冻结注释，文档（ROADMAP/DECISIONS/README/m4-PRD）统一 ⏸ 暂缓口径并写明恢复条件。同时完成 pre-opensource-polish 父任务规划：drop-mobile-scope 已 archive；brand-visual-reframe（C 档大改：归巢叙事 UI 重塑）三件套 PRD/design/implement 写完待 start。顺带 archive 已完成的 ux-overhaul 父任务。flutter analyze 0 issue / 49 tests 全过。

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `30ad58f` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete
