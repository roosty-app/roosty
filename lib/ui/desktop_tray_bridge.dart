import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/core_providers.dart';
import 'desktop_lifecycle.dart';

/// Default tray icon path passed to [TrayManager.setIcon].
const _defaultTrayIcon = 'windows/runner/resources/app_icon.ico';

/// A single shared controller other parts of the UI can use to query the tray
/// position and trigger a short flash without needing a widget tree reference.
///
/// `DesktopTrayBridge` wires its state into this controller during init. When
/// the bridge is not mounted (e.g. unit tests, non-Windows platforms) all
/// methods become safe no-ops.
class TrayController {
  TrayController._();

  static final TrayController instance = TrayController._();

  _DesktopTrayBridgeState? _state;

  void _attach(_DesktopTrayBridgeState state) {
    _state = state;
  }

  void _detach(_DesktopTrayBridgeState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  /// Returns the tray icon screen bounds in logical pixels, or `null` when the
  /// bridge is not mounted or `tray_manager` reports nothing usable.
  Future<Rect?> getTrayBounds() async {
    return _state?.getTrayBounds();
  }

  /// Briefly toggles the tray icon to draw the user's eye to it. Defaults to
  /// blinking twice within 500 ms.
  Future<void> flashTrayIcon({
    Duration total = const Duration(milliseconds: 500),
    int count = 2,
  }) async {
    await _state?.flashTrayIcon(total: total, count: count);
  }
}

class DesktopTrayBridge extends ConsumerStatefulWidget {
  const DesktopTrayBridge({super.key});

  @override
  ConsumerState<DesktopTrayBridge> createState() => _DesktopTrayBridgeState();
}

class _DesktopTrayBridgeState extends ConsumerState<DesktopTrayBridge>
    with TrayListener {
  bool? _lastClipboardEnabled;
  bool _listening = false;
  bool _attached = false;
  Timer? _feedbackTimer;
  Timer? _flashTimer;
  Timer? _flashRestoreTimer;
  int _flashCallSeq = 0;

  @override
  void initState() {
    super.initState();
    if (ref.read(isWindowsProvider)) {
      _listening = true;
      trayManager.addListener(this);
      TrayController.instance._attach(this);
      _attached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_initTray());
        }
      });
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _flashTimer?.cancel();
    _flashRestoreTimer?.cancel();
    if (_attached) {
      TrayController.instance._detach(this);
    }
    if (_listening) {
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isWindowsProvider)) {
      return const SizedBox.shrink();
    }

    final clipboardEnabled = ref.watch(effectiveClipboardWatchingProvider);
    if (_lastClipboardEnabled != clipboardEnabled) {
      _lastClipboardEnabled = clipboardEnabled;
      unawaited(_setMenu(clipboardEnabled));
    }

    ref.listen<CaptureState>(captureControllerProvider, (previous, next) {
      final message = next.message ?? '';
      if (message.startsWith('已归巢')) {
        unawaited(_flashSuccess());
      } else if (message.startsWith('归巢失败')) {
        unawaited(_showFailure(message));
      }
    });

    return const SizedBox.shrink();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showMainWindow());
  }

  @override
  void onTrayIconMouseUp() {
    unawaited(_showMainWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayIconRightMouseUp() {
    unawaited(trayManager.popUpContextMenu());
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setIcon(_defaultTrayIcon);
      await trayManager.setToolTip('Roosty');
      await _setMenu(ref.read(effectiveClipboardWatchingProvider));
    } on MissingPluginException {
      // Widget tests run without desktop plugin registration.
    }
  }

  Future<void> _setMenu(bool clipboardEnabled) async {
    try {
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(
              key: 'open',
              label: '打开 Roosty',
              onClick: (_) => unawaited(_showMainWindow()),
            ),
            MenuItem(
              key: 'toggle_clipboard',
              label: clipboardEnabled ? '暂停剪贴板监听' : '恢复剪贴板监听',
              onClick: (_) => ref
                  .read(clipboardWatchingSessionOverrideProvider.notifier)
                  .setEnabledForSession(!clipboardEnabled),
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'exit',
              label: '退出',
              onClick: (_) => unawaited(exitRoosty()),
            ),
          ],
        ),
      );
    } on MissingPluginException {
      // Ignore in tests.
    }
  }

  Future<void> _showMainWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } on MissingPluginException {
      // Ignore in tests.
    }
  }

  Future<void> _flashSuccess() async {
    try {
      await trayManager.setToolTip('Roosty：已归巢');
      await trayManager.setTitle('✓');
      _resetTrayFeedbackLater();
    } on MissingPluginException {
      // Ignore in tests.
    }
  }

  Future<void> _showFailure(String message) async {
    try {
      await trayManager.setToolTip('Roosty：$message');
      await trayManager.setTitle('!');
    } on MissingPluginException {
      // Ignore in tests.
    }
  }

  void _resetTrayFeedbackLater() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 1), () async {
      try {
        await trayManager.setToolTip('Roosty');
        await trayManager.setTitle('');
      } on MissingPluginException {
        // Ignore in tests.
      }
    });
  }

  /// Reads tray bounds from `tray_manager`. Returns `null` on platforms
  /// without a tray icon registered, when the plugin is missing (tests), or
  /// when the native side cannot resolve a rectangle yet.
  Future<Rect?> getTrayBounds() async {
    try {
      return await trayManager.getBounds();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Blinks the tray icon by toggling between the default icon and a brief
  /// "blank" state. `tray_manager` does not expose a hide-icon API, so the
  /// off-frames re-call [TrayManager.setIcon] with the same path; the visual
  /// effect on Windows is a short flicker which is enough to read "received".
  ///
  /// The implementation prefers a second highlighted icon if it ships with
  /// the app; today only `app_icon.ico` exists, so we re-use the default
  /// path and rely on the native redraw to communicate the blink.
  Future<void> flashTrayIcon({
    Duration total = const Duration(milliseconds: 500),
    int count = 2,
  }) async {
    if (count <= 0 || total <= Duration.zero) {
      return;
    }
    _flashCallSeq += 1;
    final callId = _flashCallSeq;
    _flashTimer?.cancel();
    _flashRestoreTimer?.cancel();

    final stepMicros = total.inMicroseconds ~/ (count * 2);
    if (stepMicros <= 0) {
      return;
    }
    final step = Duration(microseconds: stepMicros);

    var ticks = 0;
    final totalTicks = count * 2;
    var highlighted = false;

    Future<void> apply(bool useHighlight) async {
      try {
        // Today the highlight variant is just the default icon re-applied;
        // the flicker comes from the native redraw. If the project later
        // ships an `app_icon_highlight.ico`, swap the path here.
        await trayManager.setIcon(_defaultTrayIcon);
      } on MissingPluginException {
        // Tests run without the native plugin; the timer loop still keeps
        // its cadence so unit tests can observe the call count.
      } on PlatformException {
        // Native side refused; skip without crashing the animation.
      }
    }

    await apply(false);
    _flashTimer = Timer.periodic(step, (timer) {
      if (callId != _flashCallSeq) {
        timer.cancel();
        return;
      }
      ticks += 1;
      highlighted = !highlighted;
      unawaited(apply(highlighted));
      if (ticks >= totalTicks) {
        timer.cancel();
      }
    });

    _flashRestoreTimer = Timer(total, () {
      if (callId != _flashCallSeq) {
        return;
      }
      _flashTimer?.cancel();
      unawaited(apply(false));
    });
  }
}
