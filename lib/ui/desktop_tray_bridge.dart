import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/core_providers.dart';
import 'desktop_lifecycle.dart';

class DesktopTrayBridge extends ConsumerStatefulWidget {
  const DesktopTrayBridge({super.key});

  @override
  ConsumerState<DesktopTrayBridge> createState() => _DesktopTrayBridgeState();
}

class _DesktopTrayBridgeState extends ConsumerState<DesktopTrayBridge>
    with TrayListener {
  bool? _lastClipboardEnabled;
  bool _listening = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    if (ref.read(isWindowsProvider)) {
      _listening = true;
      trayManager.addListener(this);
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
      await trayManager.setIcon('windows/runner/resources/app_icon.ico');
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
}
