import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopWindowLifecycleBridge extends StatefulWidget {
  const DesktopWindowLifecycleBridge({super.key});

  @override
  State<DesktopWindowLifecycleBridge> createState() =>
      _DesktopWindowLifecycleBridgeState();
}

class _DesktopWindowLifecycleBridgeState
    extends State<DesktopWindowLifecycleBridge>
    with WindowListener {
  Timer? _hiddenTooltipTimer;
  bool _firstHideHintShown = false;
  bool _listening = false;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _listening = true;
      windowManager.addListener(this);
      unawaited(_configureWindowLifecycle());
    }
  }

  @override
  void dispose() {
    _hiddenTooltipTimer?.cancel();
    if (_listening) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_hideToTray());
  }

  @override
  void onWindowMinimize() {
    unawaited(_hideToTray());
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  Future<void> _configureWindowLifecycle() async {
    try {
      await windowManager.setPreventClose(true);
    } on MissingPluginException {
      // Widget tests run without native plugin registration.
    }
  }

  Future<void> _hideToTray() async {
    try {
      await windowManager.hide();
      if (!_firstHideHintShown) {
        _firstHideHintShown = true;
        await _showHiddenTooltip();
      }
    } on MissingPluginException {
      // Widget tests run without native plugin registration.
    }
  }

  Future<void> _showHiddenTooltip() async {
    if (!Platform.isWindows) {
      return;
    }
    await trayManager.setToolTip('Roosty 已隐藏到托盘，点托盘图标恢复');
    _hiddenTooltipTimer?.cancel();
    _hiddenTooltipTimer = Timer(const Duration(seconds: 5), () async {
      try {
        await trayManager.setToolTip('Roosty');
      } on MissingPluginException {
        // Widget tests run without native plugin registration.
      }
    });
  }
}

Future<void> exitRoosty() async {
  try {
    if (Platform.isWindows) {
      await trayManager.destroy();
    }
    await windowManager.destroy();
  } on MissingPluginException {
    // Widget tests run without native plugin registration.
  }
}

Future<void> confirmExitRoosty(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('退出 Roosty？'),
        content: const Text('退出后托盘、剪贴板监听和后台归巢都会停止。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      );
    },
  );
  if (shouldExit == true) {
    await exitRoosty();
  }
}
