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
