import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../core/core_providers.dart';
import '../core/mini_card.dart';
import 'desktop_tray_bridge.dart';
import 'mini_card_standalone_app.dart';

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

    // All three exits (archive / ignoreOnce / blockDomain) share the same
    // "card flies into the tray" feedback: the standalone window is already
    // animating itself toward the tray vector, so we trigger the tray-icon
    // blink here to close the loop visually.
    unawaited(TrayController.instance.flashTrayIcon());

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
      final indexFromBottom = cards.length - 1 - index;
      final flight = await _computeFlightVector(indexFromBottom);
      final arguments = MiniCardWindowArguments(
        card: card,
        indexFromBottom: indexFromBottom,
        flightDx: flight?.dx,
        flightDy: flight?.dy,
      );
      final existing = _windows[card.id];
      if (existing == null) {
        await _createWindow(arguments);
      } else {
        await _updateWindow(existing, arguments);
      }
    }
  }

  /// Computes the delta from the standalone mini-card window center to the
  /// tray icon center, in logical pixels.
  ///
  /// The card window is sized 380x200 and positioned in the bottom-right of
  /// the primary display visible region (mirrors [_positionWindow] inside
  /// [MiniCardStandaloneApp]). Tray bounds come from `tray_manager`. When
  /// either piece is unavailable we fall back to a +200/+200 vector so the
  /// dismiss animation still drifts toward the bottom-right corner instead
  /// of the upper-left void.
  Future<Offset?> _computeFlightVector(int indexFromBottom) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final visiblePosition = display.visiblePosition ?? Offset.zero;
      final visibleSize = display.visibleSize ?? display.size;
      final cardLeft = visiblePosition.dx +
          visibleSize.width -
          miniCardWindowSize.width -
          miniCardWindowMargin;
      final cardTop = visiblePosition.dy +
          visibleSize.height -
          miniCardWindowSize.height -
          miniCardWindowMargin -
          indexFromBottom *
              (miniCardWindowSize.height + miniCardWindowGap);
      final cardCenter = Offset(
        cardLeft + miniCardWindowSize.width / 2,
        cardTop + miniCardWindowSize.height / 2,
      );

      final trayBounds = await TrayController.instance.getTrayBounds();
      if (trayBounds != null && trayBounds.width > 0 && trayBounds.height > 0) {
        return trayBounds.center - cardCenter;
      }
    } on MissingPluginException {
      // Tests / non-Windows: fall through to default vector.
    } catch (_) {
      // Display or tray probe failed; fall through.
    }
    return const Offset(200, 200);
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
