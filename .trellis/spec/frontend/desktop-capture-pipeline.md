# Desktop Capture Pipeline

> Executable contracts for the Windows clipboard-to-Obsidian capture loop.

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

## Filename Contract

- Format: `YYYY-MM-DD-<title-slug>.md`.
- Keep Chinese characters.
- Remove Windows-invalid characters: `\ / : * ? " < > |`.
- Collapse whitespace to `-`.
- Use `untitled` when the result is empty.
- Add numeric suffixes for duplicates before `.md`.
