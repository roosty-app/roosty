import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core_providers.dart';
import '../core/mini_card.dart';

class DesktopMiniCardWindowHost extends ConsumerStatefulWidget {
  const DesktopMiniCardWindowHost({super.key});

  @override
  ConsumerState<DesktopMiniCardWindowHost> createState() =>
      _DesktopMiniCardWindowHostState();
}

class _DesktopMiniCardWindowHostState
    extends ConsumerState<DesktopMiniCardWindowHost> {
  final _actionChannel = const WindowMethodChannel(
    miniCardActionChannel,
    mode: ChannelMode.unidirectional,
  );
  final Map<String, WindowController> _windows = {};

  bool _syncScheduled = false;
  bool _actionChannelRegistered = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      unawaited(_registerActionChannel());
    }
  }

  @override
  void dispose() {
    if (_actionChannelRegistered) {
      unawaited(_actionChannel.setMethodCallHandler(null));
    }
    for (final controller in _windows.values) {
      unawaited(_requestClose(controller));
    }
    _windows.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const SizedBox.shrink();
    }

    final cards = ref.watch(miniCardControllerProvider).cards;
    _scheduleSync(cards);
    return const SizedBox.shrink();
  }

  Future<void> _registerActionChannel() async {
    try {
      await _actionChannel.setMethodCallHandler(_handleAction);
      _actionChannelRegistered = true;
    } on MissingPluginException {
      // Widget tests run without desktop plugin registration.
    } on WindowChannelException catch (error) {
      ref
          .read(captureControllerProvider.notifier)
          .showMessage('Mini 窗通道初始化失败：$error');
    }
  }

  Future<dynamic> _handleAction(MethodCall call) async {
    if (call.method != miniCardActionMethod) {
      throw MissingPluginException('No handler for ${call.method}');
    }
    final arguments = Map<String, dynamic>.from(call.arguments as Map);
    final cardId = arguments['cardId'] as String?;
    final action = arguments['action'] as String?;
    if (cardId == null || action == null) {
      return false;
    }

    switch (action) {
      case 'archive':
        unawaited(
          ref.read(captureControllerProvider.notifier).archiveMiniCard(cardId),
        );
        return true;
      case 'ignoreOnce':
        ref.read(miniCardControllerProvider.notifier).ignoreOnce(cardId);
        return true;
      case 'blockDomain':
        unawaited(
          ref.read(miniCardControllerProvider.notifier).blockDomain(cardId),
        );
        return true;
      default:
        return false;
    }
  }

  void _scheduleSync(List<MiniCardModel> cards) {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      unawaited(_syncWindows(cards));
    });
  }

  Future<void> _syncWindows(List<MiniCardModel> cards) async {
    if (!mounted) {
      return;
    }

    final currentIds = cards.map((card) => card.id).toSet();
    for (final id in _windows.keys.toList()) {
      if (!currentIds.contains(id)) {
        final controller = _windows.remove(id);
        if (controller != null) {
          unawaited(_requestClose(controller));
        }
      }
    }

    for (var index = 0; index < cards.length; index += 1) {
      final card = cards[index];
      final arguments = MiniCardWindowArguments(
        card: card,
        indexFromBottom: cards.length - 1 - index,
      );
      final existing = _windows[card.id];
      if (existing == null) {
        await _createWindow(arguments);
      } else {
        await _updateWindow(existing, arguments);
      }
    }
  }

  Future<void> _createWindow(MiniCardWindowArguments arguments) async {
    try {
      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: jsonEncode(arguments.toJson()),
        ),
      );
      _windows[arguments.card.id] = controller;
    } on MissingPluginException {
      // Tests can instantiate the widget tree without native plugins.
    } catch (error) {
      ref
          .read(captureControllerProvider.notifier)
          .showMessage('Mini 窗创建失败：$error');
    }
  }

  Future<void> _updateWindow(
    WindowController controller,
    MiniCardWindowArguments arguments,
  ) async {
    try {
      await controller.invokeMethod(miniCardUpdateMethod, arguments.toJson());
    } on MissingPluginException {
      // Ignore in tests.
    } catch (_) {
      // The child window may already be closing; the next state sync will clean up.
    }
  }

  Future<void> _requestClose(WindowController controller) async {
    try {
      await controller.invokeMethod(miniCardCloseMethod);
    } on MissingPluginException {
      // Ignore in tests.
    } catch (_) {
      try {
        await controller.hide();
      } catch (_) {
        // The native window may already be gone.
      }
    }
  }
}
