# State Management

> How state is managed in this project.

---

## Overview

Roosty uses Riverpod for app wiring and state. Providers live near the layer they
serve: config providers in `lib/config/`, pipeline/history providers in
`lib/core/`, and future feature-specific providers in the owning layer.

---

## State Categories

- Local UI state stays inside widgets unless another layer needs it.
- App configuration is global and loaded through `appConfigProvider`.
- Pipeline and history are global providers owned by `lib/core/`.
- Long-lived settings must be persisted through `ConfigRepository`, not stored
  only in widget state.

---

## When to Use Global State

- Use global providers for vault path, clipboard listening status, LLM settings,
  pipeline composition, and capture history.
- Keep temporary form edits local until the user saves them.

---

## Server State

M0 has no server state. Future LLM calls should be modeled as processor work and
must degrade gracefully when the key is missing or the request fails.

---

## Common Mistakes

- Do not hardcode API keys or secrets in providers.
- Do not enable clipboard watching by default; the persisted default is `false`.
- Do not use immutable const lists for mutable `Item.tags`; processors may append
  tags later in the pipeline.
