# Capture Pipeline

> Executable contracts for the clipboard/share-to-Obsidian capture loop.

---

## Scenario: Confirmed Desktop URL Capture

### 1. Scope / Trigger

- Trigger: features that move a desktop URL from clipboard/manual input through
  `Source -> Fetcher -> Processor -> Sink`.
- Applies to: `lib/sources/`, `lib/fetchers/`, `lib/processors/`, `lib/sinks/`,
  `lib/core/`, and the UI providers that wire them.

### 2. Signatures

- `Source.watch(): Stream<Item>` emits candidate items only; it must not archive.
- `Fetcher.canHandle(String url): bool` returns true for supported URLs.
- `Fetcher.fetch(Item item): Future<Item>` enriches the same shared item model.
- `Processor.process(Item item): Future<Item>` mutates or returns the item.
- `Sink.write(Item item): Future<void>` persists the item.
- `Pipeline.run(Item item): Future<Item>` executes fetch, processors, then sinks.

### 3. Contracts

- Clipboard watching defaults to disabled in persisted config.
- Clipboard URL detection accepts only `http://` and `https://` URLs for M1.
- Captured clipboard URLs enter app state as pending items; user confirmation is
  required before `Pipeline.run` is called.
- Manual URL input may call the pipeline directly because the user explicitly
  submitted it.
- `ObsidianSink` writes to `<vault>/Roosty/*.md` and must use the root vault path
  from config.
- Markdown output must keep the ROADMAP schema:

  ```markdown
  ---
  title: "..."
  source: web
  url: https://...
  author: "..."
  captured: 2026-06-14T12:30:00+08:00
  summary: ""
  tags: [roosty/inbox]
  status: unread
  ---
  ```

### 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| Clipboard contains no HTTP(S) URL | emit nothing |
| Same URL repeats inside dedupe window | emit only once |
| Vault path is missing | show an app-state message; do not write |
| Fetcher unsupported or fetch fails | keep the item and write fallback body |
| Processor fails in M1 | continue to sink; do not drop capture |
| Output filename already exists | append `-2`, `-3`, etc. |

Fallback body:

```dart
const fallbackBody = '> ⚠️ 正文未抓取，点击上方链接查看原文';
```

### 5. Good/Base/Bad Cases

- Good: copying a real URL queues a pending item; confirming writes a note with
  title, URL, captured timestamp, tags, and body.
- Base: manually pasted URL writes through the same pipeline and appears in
  history.
- Bad: network fetch fails; the note is still written with URL/title and fallback
  body.

### 6. Tests Required

- URL extraction and clipboard dedupe tests.
- Fetcher `canHandle` and HTML metadata/body extraction tests.
- Pipeline order and fetch-failure fallback tests.
- Markdown schema, filename sanitization, and duplicate filename tests.
- Widget smoke test for the desktop loop shell.
- Windows milestone verification from an ASCII junction when native plugins are
  involved.

### 7. Wrong vs Correct

#### Wrong

```dart
clipboardSource.watch().listen((item) {
  pipeline.run(item); // Archives without consent.
});
```

#### Correct

```dart
clipboardSource.watch().listen((item) {
  captureController.queue(item); // UI asks for confirmation first.
});
```

---

## Scenario: Windows Clipboard Mini Card Capture

### 1. Scope / Trigger

- Trigger: Windows clipboard URL captures that should ask for confirmation
  without using the main in-app pending capture card.
- Applies to: `lib/core/`, `lib/ui/`, `lib/config/`, `lib/main.dart`, Windows
  plugin registration, and tests for URL rules / mini-card state.
- Does not apply to: Android share capture, manual URL input, or macOS/Linux
  clipboard UX. Those paths keep their existing behavior unless a task says
  otherwise.

### 2. Signatures

- `CaptureController.handleClipboardCapture(Item item): void` routes Windows
  clipboard captures to the mini-card controller and non-Windows captures to
  the existing pending item.
- `MiniCardController.show(Item item): void` creates one visible candidate card
  unless the URL is temporarily ignored or its exact domain is blocked.
- `MiniCardController.takeForArchive(String cardId): Future<Item>?` removes a
  card immediately and returns the in-flight enriched item future.
- `MiniCardController.ignoreOnce(String cardId): void` hides the card and stores
  the exact URL in an in-memory TTL map.
- `MiniCardController.blockDomain(String cardId): Future<void>` hides the card
  and persists the URL host through `AppConfigController.addDomainToBlocklist`.
- `Pipeline.enrich(Item item): Future<Item>` runs fetchers and processors only.
- `Pipeline.write(Item item): Future<void>` writes an already-enriched item to
  sinks.
- `DesktopMiniCardWindowHost` owns desktop child-window lifecycle and registers
  the `roosty/mini_card_actions` channel.
- `MiniCardStandaloneApp` runs in the child engine and renders a serialized
  `MiniCardWindowArguments` payload.
- `applyMiniWindowStyles(): Future<void>` applies Windows extended styles:
  `WS_EX_NOACTIVATE`, `WS_EX_TOOLWINDOW`, and `WS_EX_TOPMOST`.

### 3. Contracts

- `window_manager` manages only the current Flutter desktop window. It does not
  create multiple independent Flutter windows. Use `desktop_multi_window` for
  independent mini-card windows, then use `window_manager` inside each child
  engine to size/position/style that child.
- Windows runner must call `DesktopMultiWindowSetWindowCreatedCallback` and
  `RegisterPlugins` for child engines; otherwise plugins like `window_manager`
  and `screen_retriever` are missing in mini windows.
- The parent window owns pipeline, history, ignore TTL, and domain blocklist.
  Child windows receive serialized card state and send button actions back over
  `WindowMethodChannel`; children must not run the archive pipeline directly.
- Windows clipboard captures must not set `CaptureState.pendingItem`; they enter
  `MiniCardController` instead. Manual URL input and non-Windows clipboard
  captures may keep using the main pending card.
- Mini-card state holds at most 3 cards. When a fourth URL arrives, remove the
  oldest card and treat that URL as "ignore once".
- Ignore-once is exact-URL, in memory only, and expires after 30 minutes.
- Persistent domain blocking uses shared_preferences key
  `flutter.domainBlocklist` with normalized exact hosts. Subdomains are not
  implicitly blocked by a parent domain.
- Enrichment for preview must not call sinks. Archiving from a mini card awaits
  the enrichment future and then writes the enriched item.
- Tray feedback is passive: no notification bubble; success/failure may update
  tray title/tooltip briefly.

### 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| URL is in the 30-minute ignore map | Do not show a card; do not persist the ignore |
| URL host equals a blocked domain | Do not show a card |
| URL host is a subdomain of a blocked parent | Show a card unless that exact subdomain is blocked |
| More than 3 active mini cards | Remove oldest card and ignore that URL once |
| Preview fetch or processing fails | Keep the card actionable and allow archive fallback |
| User archives before preview completes | Remove card immediately; background enrichment continues before write |
| Vault config is missing | Do not write; surface the existing capture message |
| Desktop plugin is unavailable in widget tests | Catch `MissingPluginException`; tests must not fail |
| Child-engine plugin callback is missing | Windows build/run may create windows with broken method channels; add callback in `windows/runner/flutter_window.cpp` |

### 5. Good/Base/Bad Cases

- Good: copying a URL on Windows creates a mini-card state entry immediately,
  opens an independent right-bottom child window, fills title/summary as
  enrichment finishes, and archives only after the user clicks archive.
- Base: copying the same URL after "ignore once" does nothing for 30 minutes,
  then shows a card again after TTL expiry.
- Bad: using `window_manager` alone to resize the main app window and calling it
  a true multi-window mini notification.

### 6. Tests Required

- Unit tests for domain extraction including port and IDN host handling.
- Config repository test for default and persisted `flutter.domainBlocklist`.
- Mini-card controller tests for ignore TTL, exact-domain blocking, max-3
  overflow, and preview enrichment without sink writes.
- Widget smoke test must still cover the desktop shell and settings UI.
- Windows build verification after adding or changing desktop plugins.
- Manual E2E is still required before marking the task complete: copy URL while
  the main window is not foreground, verify right-bottom behavior, button
  actions, vault output, tray feedback, and blacklist UI.

### 7. Wrong vs Correct

#### Wrong

```dart
clipboardSource.watch().listen(captureController.queue);
// On Windows this still requires switching to the main window.
```

#### Correct

```dart
clipboardSource.watch().listen(captureController.handleClipboardCapture);
// Windows uses mini cards; other platforms keep the pending-card path.
```

#### Wrong

```dart
await windowManager.setBounds(miniBounds);
// This moves the main app window, not a separate notification window.
```

#### Correct

```dart
final controller = await WindowController.create(
  WindowConfiguration(
    hiddenAtLaunch: true,
    arguments: jsonEncode(arguments.toJson()),
  ),
);
// The child engine then uses window_manager to position its own window.
```

#### Wrong

```dart
await _archiveWith(() => miniCardController.takeForArchive(cardId)!);
// takeForArchive returns the preview enrichment future only; no sink writes.
```

#### Correct

```dart
await _archiveWith(() async {
  final item = await miniCardController.takeForArchive(cardId)!;
  await pipeline.write(item);
  return item;
});
```

---

## Scenario: Desktop Tray And Window Lifecycle

### 1. Scope / Trigger

- Trigger: desktop behavior that keeps Roosty resident in the system tray while
  preserving clipboard capture and mini-card flows.
- Applies to: `lib/main.dart`, `lib/ui/desktop_tray_bridge.dart`,
  `lib/ui/desktop_lifecycle.dart`, `lib/ui/home_screen.dart`,
  `lib/core/core_providers.dart`, and desktop widget/integration tests.
- Does not apply to: Android share capture. Android must keep the mobile share
  lifecycle and must not enable clipboard watching.

### 2. Signatures

- `DesktopTrayBridge` registers a `TrayListener` and owns tray icon/menu state.
- `DesktopWindowLifecycleBridge` registers a `WindowListener` and owns host
  window close/minimize behavior.
- `exitRoosty(): Future<void>` is the shared explicit-exit path.
- `confirmExitRoosty(BuildContext context): Future<void>` asks once before
  calling `exitRoosty`.
- `clipboardWatchingSessionOverrideProvider: NotifierProvider<..., bool?>`
  stores a session-only tray pause/resume override.
- `effectiveClipboardWatchingProvider: Provider<bool>` combines persisted
  config and the session override.

### 3. Contracts

- Main desktop startup must call `windowManager.ensureInitialized()` before
  using window APIs, and must call `windowManager.setPreventClose(true)` for
  host windows that should hide instead of exiting.
- Mini-card child windows are not host windows. They may close normally and
  must not register the host lifecycle bridge.
- Host `onWindowClose` must call `windowManager.hide()` and must not call
  `windowManager.destroy()`.
- Host `onWindowMinimize` must call `windowManager.hide()` and must not leave a
  taskbar-minimized window.
- Actual process exit is allowed only through explicit exit UI:
  tray menu "退出" or settings "退出 Roosty" after confirmation.
- Tray menu "暂停/恢复剪贴板监听" is session-only. It updates
  `clipboardWatchingSessionOverrideProvider`; it must not write
  `AppConfig.clipboardWatchingEnabled` or shared_preferences.
- UI that displays clipboard listening state must read
  `effectiveClipboardWatchingProvider`, not only persisted config, so tray
  menu changes are reflected immediately in the settings switch.
- Windows `tray_manager 0.5.3` dispatches `WM_LBUTTONUP` as Dart
  `onTrayIconMouseDown` and `WM_RBUTTONUP` as `onTrayIconRightMouseDown`.
  Roosty must handle those callbacks; `MouseUp` handlers may remain as
  compatibility fallbacks.
- First hide-to-tray action may set the tray tooltip to explain where Roosty
  went, then restore the default tooltip after a short timeout.

### 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| User left-clicks tray icon on Windows | Show and focus the main window |
| User double-clicks tray icon | Show and focus the main window |
| User right-clicks tray icon | Open the tray context menu |
| User clicks tray menu pause/resume | Effective clipboard state changes; persisted config is unchanged |
| Settings switch is visible after tray pause | Switch shows the effective paused state |
| User clicks X on host window | Main window hides; process and clipboard watcher remain alive |
| User minimizes host window | Main window hides to tray; process remains alive |
| User clicks settings exit | Show confirmation before destroying tray/window |
| User clicks tray exit | Destroy tray icon and window |
| Desktop plugins are missing in widget tests | Catch `MissingPluginException` and keep tests deterministic |

### 5. Good/Base/Bad Cases

- Good: Roosty is hidden from the taskbar, remains in the tray, and still shows
  mini cards when clipboard watching is effectively enabled.
- Base: tray pause stops clipboard watching only for the current process, and a
  restart returns to the persisted user preference.
- Bad: the tray menu updates a hidden override while the settings UI still reads
  stale persisted config, making the switch disagree with the actual watcher.

### 6. Tests Required

- Widget integration test must pump the real app tree with `isWindowsProvider`
  overridden and mock the `tray_manager` / `window_manager` platform channels.
- Test tray icon events by sending plugin method calls such as
  `onTrayIconMouseDown`, `onTrayIconRightMouseDown`, and
  `onTrayMenuItemClick`; assert `window_manager.show/focus` and
  `tray_manager.popUpContextMenu` calls.
- Test tray pause/resume by invoking the menu item id returned through
  `setContextMenu`; assert the settings switch changes while
  `clipboardWatchingEnabled` in shared_preferences does not.
- Test `onEvent(close)` and `onEvent(minimize)`; assert `hide` is called and
  `destroy` is not.
- Windows Release/manual verification is required before finishing lifecycle
  tasks: click the real tray icon/menu, close/minimize the real window, and
  verify clipboard capture still works after hiding.

### 7. Wrong vs Correct

#### Wrong

```dart
@override
void onTrayIconMouseUp() => _showMainWindow();

@override
void onTrayIconRightMouseUp() => trayManager.popUpContextMenu();
// On Windows tray_manager 0.5.3 sends mouse-up native events as MouseDown.
```

#### Correct

```dart
@override
void onTrayIconMouseDown() => _showMainWindow();

@override
void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();
```

#### Wrong

```dart
SwitchListTile(value: config.clipboardWatchingEnabled);
// Ignores session-only tray pause/resume state.
```

#### Correct

```dart
final enabled = ref.watch(effectiveClipboardWatchingProvider);
SwitchListTile(value: enabled);
```

#### Wrong

```dart
void onWindowClose() {
  windowManager.destroy();
}
```

#### Correct

```dart
void onWindowClose() {
  windowManager.hide();
}
```

---

## Scenario: Android System Share Capture

### 1. Scope / Trigger

- Trigger: Android users choose Roosty from the system share sheet for
  `ACTION_SEND` text payloads.
- Applies to: `lib/sources/`, `lib/core/`, `lib/sinks/`, `lib/config/`,
  `lib/ui/`, Android `MainActivity`, and `AndroidManifest.xml`.
- Does not apply to: iOS share extensions or mobile background clipboard
  watching.

### 2. Signatures

- `ShareIntentSource.watch(): Stream<Item>` emits shared items and never writes
  files itself.
- `itemsFromSharedMedia(List<SharedMediaFile>): List<Item>` normalizes plugin
  payloads into the shared `Item` model.
- `AndroidSafVault.pickDirectory(): Future<String?>` returns a persisted SAF
  tree URI string or `null` when cancelled.
- `AndroidSafVault.writeTextFile({treeUri, directoryName, fileName, content})`
  writes UTF-8 markdown through the `roosty/android_saf` MethodChannel.
- `ObsidianSink.android({vaultUri, androidSaf})` keeps the same
  `Sink.write(Item)` interface as desktop.
- `AppConfig.androidVaultUri` is the persisted Android vault authorization.

### 3. Contracts

- Android manifest must expose `MainActivity` as `singleTop` and add an
  `ACTION_SEND` + `CATEGORY_DEFAULT` + `text/*` intent-filter.
- Cold-start shares are read from
  `ReceiveSharingIntent.instance.getInitialMedia()` and reset after a non-empty
  payload; warm shares are read from `getMediaStream()`.
- Shared text is built from non-empty `SharedMediaFile.path` and `message`.
  If an HTTP(S) URL exists, the first URL becomes `Item.url`.
- Source platform is derived from URL host:
  `mp.weixin.qq.com -> wechat`, `x.com` / `*.x.com` / `twitter.com` /
  `*.twitter.com -> x`, `xiaohongshu.com` / `xhslink.com -> xiaohongshu`,
  known video hosts -> `video`, otherwise `web`.
- Plain text without a URL becomes an `Item` with a synthetic
  `roosty://shared-text/<timestamp>` URL, `rawText` set to the shared text, and
  `source: web`; the pipeline must still archive it via fallback/no-fetch path.
- Mobile system share is explicit user intent, so the controller calls
  `archiveShared(item)` directly. Do not queue a pending confirmation.
- Android must not enable clipboard watching; the UI disables the clipboard
  toggle when `Platform.isAndroid` is true.
- Android vault writes must use SAF: `ACTION_OPEN_DOCUMENT_TREE`, persisted
  URI permission, and `<authorized tree>/Roosty/*.md`. Do not write arbitrary
  filesystem paths on Android.

### 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| Shared payload has no text or URL | emit nothing |
| Initial share payload is non-empty | emit items, then call `reset()` |
| App has no Android vault URI | show a setup message; do not run sink |
| User cancels SAF picker | keep existing config unchanged |
| SAF write returns no file name | throw `PlatformException(empty_result)` |
| Target markdown filename already exists | append `-2`, `-3`, etc. in SAF writer |
| Web fetcher does not support synthetic text URL | keep `rawText` and continue to processors/sink |

### 5. Good/Base/Bad Cases

- Good: sharing a WeChat article URL to Roosty writes a markdown file in the
  SAF-authorized `Roosty` directory without a confirmation prompt.
- Base: sharing plain text writes a markdown note whose body is the shared
  text and whose URL is synthetic.
- Bad: SAF permission is missing; the app shows the vault setup message and
  does not crash.

### 6. Tests Required

- Unit tests for initial share, warm stream share, reset behavior, plain text
  fallback, and source-platform host detection.
- Sink tests asserting `ObsidianSink.android` calls the SAF channel wrapper
  with `directoryName: Roosty`, generated markdown filename, and content.
- Config tests asserting `androidVaultUri` defaults to null and persists.
- Widget tests asserting Android UI shows vault authorization and disables the
  clipboard toggle.
- Build verification from an ASCII junction: `flutter build apk --debug`.
- End-to-end verification on a real device or emulator: share from another app,
  authorize SAF vault, and confirm a markdown file is created.

### 7. Wrong vs Correct

#### Wrong

```dart
shareIntentSource.watch().listen(captureController.queue);
// Mobile share already expresses intent; confirmation adds friction.
```

#### Correct

```dart
shareIntentSource.watch().listen(captureController.archiveShared);
```

#### Wrong

```dart
ObsidianSink(vaultPath: '/sdcard/Documents/Vault');
// Android scoped storage can block arbitrary path writes.
```

#### Correct

```dart
ObsidianSink.android(vaultUri: config.androidVaultUri!);
```

---

## Filename Contract

- Format: `YYYY-MM-DD-<title-slug>.md`.
- Keep Chinese characters.
- Remove Windows-invalid characters: `\ / : * ? " < > |`.
- Collapse whitespace to `-`.
- Use `untitled` when the result is empty.
- Add numeric suffixes for duplicates before `.md`.

---

## Scenario: AI Summary Processor

### 1. Scope / Trigger

- Trigger: features that add LLM-backed processing between `Fetcher` and `Sink`.
- Applies to: `lib/processors/`, `lib/config/`, `lib/core/`, `lib/sinks/`,
  and UI settings that persist LLM configuration.

### 2. Signatures

- `LlmClient.complete(List<Map<String, String>> messages): Future<String>`
  posts one OpenAI-compatible chat completion request.
- `SummarizeProcessor.process(Item item): Future<Item>` reads `item.rawText`
  and mutates `item.summary` / `item.tags` when summary generation succeeds.
- `AppConfig.llm: LlmConfig` owns `baseUrl`, `apiKey`, and `model`; UI writes
  these through `AppConfigController.updateLlmConfig`.

### 3. Contracts

- Endpoint: `POST {baseUrl}/chat/completions`.
- Headers: `Authorization: Bearer {apiKey}` and
  `Content-Type: application/json`.
- Request body fields:
  - `model`: trimmed configured model name.
  - `messages`: OpenAI chat messages with `role` and `content`.
- Response body:
  - Read `choices[0].message.content` as text.
  - Processor expects that text to contain a JSON object with:
    `summary: string`, `highlights: string[]`, `tags: string[]`.
- `summary` follows the source content language. `item.summary` may contain
  the one-sentence summary plus Markdown bullet highlights.
- `ObsidianSink` writes only the first non-empty summary line to frontmatter
  `summary`, while the `## 摘要` body keeps the detailed multiline summary.
- Generated tags must be normalized into the `roosty/` namespace and appended
  after the retained default `roosty/inbox` tag.
- No LLM key may be hardcoded in code, tests, docs, or providers.

### 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| `baseUrl`, `apiKey`, or `model` is blank | Skip summary; continue to sink |
| `item.rawText` is null or blank | Skip summary; do not call LLM |
| LLM request times out | Log one processor message; continue to sink |
| LLM returns non-2xx, invalid JSON, or missing content | Log one processor message; continue to sink |
| Generated tag lacks `roosty/` prefix | Prefix and normalize before writing |
| Generated tag duplicates an existing tag | Keep one copy only |

### 5. Good/Base/Bad Cases

- Good: configured DeepSeek-compatible settings produce a one-sentence
  summary, 3-5 highlight bullets, and 2-4 `roosty/` tags in the archived note.
- Base: no API key is configured; the note is still written with source body and
  default `roosty/inbox` tag.
- Bad: the LLM returns malformed output; the capture is archived unchanged and
  no exception escapes the processor.

### 6. Tests Required

- `LlmClient` unit test asserts endpoint, bearer header, model, and messages.
- `SummarizeProcessor` unit tests assert success parsing, tag namespace
  normalization, no-key / empty-rawText no-op, and failure fallback.
- `ObsidianSink` test asserts frontmatter summary stays one line while
  `## 摘要` keeps the detailed body.
- Widget smoke test asserts the settings UI exposes base URL, API key, and model
  fields, with the key field in password mode.

### 7. Wrong vs Correct

#### Wrong

```dart
final response = await llm.complete(messages);
item.summary = response; // Unstructured text, tags lost, failures can leak.
```

#### Correct

```dart
try {
  final response = await llm.complete(messages);
  final parsed = parseFixedSummaryJson(response);
  item.summary = formatSummary(parsed);
  item.tags = mergeRoostyTags(item.tags, parsed.tags);
} catch (_) {
  return item; // Sink still archives the capture.
}
```
