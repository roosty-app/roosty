# Tray initialization timing

## Sources

- `tray_manager` official README: https://github.com/leanflutter/tray_manager
- Local package source: `%LOCALAPPDATA%/Pub/Cache/hosted/pub.dev/tray_manager-0.5.3`
- Local package source: `%LOCALAPPDATA%/Pub/Cache/hosted/pub.dev/window_manager-0.5.1`

## Findings

The initial hypothesis was that `trayManager.setIcon()` was called too early from
`initState`, causing tray listeners to miss native events. The official
`tray_manager` README does not support that hypothesis: its event-listening
example registers the listener in `initState` and then calls initialization from
the same lifecycle path.

The actual Windows-specific issue is in `tray_manager 0.5.3` native event
mapping:

- `WM_LBUTTONUP` invokes Dart method `onTrayIconMouseDown`
- `WM_RBUTTONUP` invokes Dart method `onTrayIconRightMouseDown`

Roosty's previous `DesktopTrayBridge` only implemented:

- `onTrayIconMouseUp`
- `onTrayIconRightMouseUp`

So Windows tray clicks reached Dart, but not the callbacks Roosty handled.

The README also documents a separate known issue where old `app_links` versions
can block menu click event propagation. Roosty does not depend on `app_links`, so
that issue is not the active cause here.

For window lifecycle, `window_manager 0.5.1` documents and implements
`setPreventClose(true)` as the close-signal interception mechanism. The Windows
native layer emits the `close` event on `WM_CLOSE` and only stops default close
when `IsPreventClose()` is true, so the host window must set prevent-close before
relying on `onWindowClose`.

## Implementation decision

- Keep listener registration in the widget lifecycle, but initialize tray setup
  after the first frame for startup stability.
- Handle Windows tray clicks through `onTrayIconMouseDown` and
  `onTrayIconRightMouseDown`; keep `MouseUp` handlers as harmless compatibility
  fallbacks.
- Add a host-window `WindowListener` that hides on close/minimize and leaves
  process exit only to explicit Roosty exit actions.
