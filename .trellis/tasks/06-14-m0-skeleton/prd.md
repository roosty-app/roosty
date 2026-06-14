# M0 — 项目骨架

**你（AI）正在执行这个任务。开发者不读此文件。**
**唯一依据：项目根目录 `ROADMAP.md`，动工前必读第 2、3 章（决策总表 + 架构）。**

---

## 目标

搭出一个能在 Windows 上 `flutter run` 启动的空 Flutter 工程，定义好 5 个核心接口，为 M1 桌面闭环铺好地基。**本里程碑不实现任何业务逻辑，只搭骨架 + 定接口。**

## 完成标准（验收）

- `flutter run -d windows` 能启动一个空白界面，不报错。
- `lib/` 下分层目录就位。
- `Source / Item / Fetcher / Processor / Sink` 五个接口已定义（可为空实现 / 抽象类）。
- 依赖已在 `pubspec.yaml` 声明且 `flutter pub get` 通过。

## 节点 checklist（做完一个勾一个）

- [x] T0.1 初始化 Flutter 工程，启用 windows + android target（`flutter create --platforms=windows,android roosty`，或在现有目录初始化）
- [x] T0.2 建分层目录：`lib/{sources,core,fetchers,processors,sinks,config,ui}`
- [x] T0.3 定义核心接口（见下方接口契约）
- [x] T0.4 引入依赖：`super_clipboard`、`receive_sharing_intent`、`http`、`html`、`yaml`、`path`、`shared_preferences`
- [x] T0.5 配置模型 + 本地持久化（vault 路径、LLM 配置三件套），用 `shared_preferences`

## 接口契约（T0.3 必须按此定义，M1/M2/M3 全部依赖，不可改签名）

```dart
// core/item.dart — 统一数据模型
class Item {
  String url;
  String? title;
  String source;        // wechat | x | xiaohongshu | video | web
  String? author;
  DateTime capturedAt;
  String? rawText;       // 抓到的正文，可空
  String? summary;       // SummarizeProcessor 回填
  List<String> tags;     // 默认 ['roosty/inbox']
  String status;         // unread | archived
}

// sources/source.dart   — 产生原始输入
abstract class Source { Stream<Item> watch(); }     // 剪贴板/分享持续产出

// fetchers/fetcher.dart — 从 URL 抓正文+元数据
abstract class Fetcher { bool canHandle(String url); Future<Item> fetch(Item item); }

// processors/processor.dart — 加工 Item（摘要等）
abstract class Processor { Future<Item> process(Item item); }

// sinks/sink.dart       — 输出 Item
abstract class Sink { Future<void> write(Item item); }
```

## 关键约束

- **动工前必读项目根 `DECISIONS.md`（工程决策硬约束）。**
- 接口签名一旦定下，后续里程碑只填实现、不改签名（除非回 ROADMAP 更新决策）。
- 暂不写任何抓取/写文件逻辑，接口方法体可 `throw UnimplementedError()`。
- 工程名 / 包名用 `roosty`；Android `applicationId` = `com.roosty.app`；Flutter stable / Dart 3.x。
- **状态管理用 Riverpod**：T0.4 依赖里加 `flutter_riverpod`，骨架按 Riverpod provider 组织（管线/配置/历史均为 provider）。
- **App UI 文案中文**，代码标识符/注释英文。

## 完成后

更新本文件 checklist → `python ./.trellis/scripts/task.py finish` → 下一个对话 `trellis:continue` 自动接手 M1。
