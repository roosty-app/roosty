# Directory Structure

> How frontend code is organized in this project.

---

## Overview

Roosty is a single Flutter app. Keep the top-level `lib/` folders aligned with
the pipeline architecture from `ROADMAP.md`: sources produce `Item`s, fetchers
enrich them, processors transform them, sinks persist them, and UI/config code
wire the flow together.

---

## Directory Layout

```
lib/
├── config/      # AppConfig, LLM config, shared_preferences repository/providers
├── core/        # Item model, Pipeline shell, app-wide core providers
├── fetchers/    # Fetcher interface and URL/content fetcher implementations
├── processors/  # Processor interface and item processors
├── sinks/       # Sink interface and output implementations
├── sources/     # Source interface and input implementations
└── ui/          # Flutter screens/widgets
```

---

## Module Organization

- Put interface contracts in their layer root, e.g. `fetchers/fetcher.dart`.
- Put implementations beside their interface, e.g. `fetchers/web_fetcher.dart`.
- Keep `Item` in `core/item.dart`; do not duplicate item payload types per layer.
- Keep app configuration in `config/`; UI should access it through providers.

---

## Naming Conventions

- File and folder names use `snake_case`.
- Dart identifiers and comments use English.
- User-facing app copy uses Chinese.
- Android `applicationId` and namespace are `com.roosty.app`.

---

## Examples

- `lib/core/item.dart` owns the shared item contract.
- `lib/config/config_repository.dart` persists config through
  `shared_preferences`.
