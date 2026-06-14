# Roosty

Roosty is a local-first clipping app for sending links and text into an
Obsidian vault.

This repository currently contains the M0 Flutter skeleton:

- Windows and Android Flutter targets
- Layered `lib/` structure for sources, fetchers, processors, sinks, config,
  core, and UI
- Core contracts for `Source`, `Item`, `Fetcher`, `Processor`, and `Sink`
- Riverpod wiring for pipeline/config/history providers
- Shared preferences persistence for vault path, clipboard listening, and LLM
  settings

## Development

```powershell
flutter pub get
flutter analyze
flutter test
```

On Windows, if the repository path contains non-ASCII characters and native
plugin builds fail, create an ASCII junction and run Windows build commands from
there:

```powershell
New-Item -ItemType Junction -Path C:\roosty-build -Target <repo-path>
Set-Location C:\roosty-build
flutter run -d windows
```
