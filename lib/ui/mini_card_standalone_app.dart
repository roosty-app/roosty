import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../core/mini_card.dart';
import '../theme/dark_theme.dart';
import '../theme/light_theme.dart';
import 'mini_card_window.dart';
import 'windows_mini_window_style.dart';

const miniCardWindowSize = Size(380, 200);
const miniCardWindowMargin = 16.0;
const miniCardWindowGap = 8.0;

class MiniCardStandaloneApp extends StatefulWidget {
  const MiniCardStandaloneApp({
    super.key,
    required this.windowController,
    required this.initialArguments,
  });

  final WindowController windowController;
  final MiniCardWindowArguments initialArguments;

  @override
  State<MiniCardStandaloneApp> createState() => _MiniCardStandaloneAppState();
}

class _MiniCardStandaloneAppState extends State<MiniCardStandaloneApp> {
  final _actionChannel = const WindowMethodChannel(
    miniCardActionChannel,
    mode: ChannelMode.unidirectional,
  );

  /// Total duration of the tray-bound exit animation. Matches design.md §4
  /// (`Curves.easeInCubic`, 280 ms) and gives the action-channel call enough
  /// time to flush before the window closes.
  static const _exitDuration = Duration(milliseconds: 280);

  /// Fallback dismiss vector when the host did not provide one. Drifts toward
  /// the bottom-right corner — the default Windows taskbar / tray position —
  /// instead of the legacy upper-left void.
  static const _fallbackFlight = Offset(200, 200);

  late MiniCardModel _card;
  late int _indexFromBottom;
  late Offset _flightOffset;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _card = widget.initialArguments.card;
    _indexFromBottom = widget.initialArguments.indexFromBottom;
    _flightOffset = _resolveFlight(widget.initialArguments);
    unawaited(widget.windowController.setWindowMethodHandler(_handleCall));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_configureAndShow());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roosty',
      theme: lightRoostyTheme,
      darkTheme: darkRoostyTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: TweenAnimationBuilder<double>(
          // Runs forward (0 -> 1) only when `_closing` flips; while the card
          // is alive `end` stays at 0 and no animation kicks off.
          tween: Tween<double>(begin: 0, end: _closing ? 1 : 0),
          duration: _exitDuration,
          curve: Curves.easeInCubic,
          builder: (context, t, child) {
            final progress = t.clamp(0.0, 1.0);
            final dx = _flightOffset.dx * progress;
            final dy = _flightOffset.dy * progress;
            final scale = 1.0 - 0.7 * progress; // 1.0 -> 0.3
            final opacity = (1.0 - progress).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
          child: MiniCardWindow(
            card: _card,
            isArchiving: false,
            onArchive: () => _sendAction('archive'),
            onIgnoreOnce: () => _sendAction('ignoreOnce'),
            onBlockDomain: () => _sendAction('blockDomain'),
          ),
        ),
      ),
    );
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case miniCardUpdateMethod:
        final arguments = MiniCardWindowArguments.fromJson(
          Map<String, dynamic>.from(call.arguments as Map),
        );
        if (!mounted || _closing) {
          return true;
        }
        setState(() {
          _card = arguments.card;
          _indexFromBottom = arguments.indexFromBottom;
          _flightOffset = _resolveFlight(arguments);
        });
        await _positionWindow();
        return true;
      case miniCardCloseMethod:
        await _closeWithAnimation();
        return true;
      default:
        throw MissingPluginException('No handler for ${call.method}');
    }
  }

  Offset _resolveFlight(MiniCardWindowArguments arguments) {
    final dx = arguments.flightDx;
    final dy = arguments.flightDy;
    if (dx == null || dy == null) {
      return _fallbackFlight;
    }
    final candidate = Offset(dx, dy);
    if (candidate.distanceSquared < 1) {
      return _fallbackFlight;
    }
    return candidate;
  }

  Future<void> _configureAndShow() async {
    final options = WindowOptions(
      size: miniCardWindowSize,
      minimumSize: miniCardWindowSize,
      maximumSize: miniCardWindowSize,
      alwaysOnTop: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      title: 'Roosty',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.setResizable(false);
      await windowManager.setMinimizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setAlwaysOnTop(true);
      await _positionWindow();
      await applyMiniWindowStyles();
      await windowManager.show(inactive: true);
      await windowManager.blur();
    });
  }

  Future<void> _positionWindow() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final visiblePosition = display.visiblePosition ?? Offset.zero;
    final visibleSize = display.visibleSize ?? display.size;
    final x =
        visiblePosition.dx +
        visibleSize.width -
        miniCardWindowSize.width -
        miniCardWindowMargin;
    final y =
        (visiblePosition.dy +
                visibleSize.height -
                miniCardWindowSize.height -
                miniCardWindowMargin -
                _indexFromBottom *
                    (miniCardWindowSize.height + miniCardWindowGap))
            .clamp(visiblePosition.dy + miniCardWindowMargin, double.infinity);
    await windowManager.setBounds(
      Rect.fromLTWH(x, y, miniCardWindowSize.width, miniCardWindowSize.height),
    );
  }

  Future<void> _sendAction(String action) async {
    if (_closing) {
      return;
    }
    setState(() {
      _closing = true;
    });
    unawaited(
      _actionChannel.invokeMethod(miniCardActionMethod, {
        'action': action,
        'cardId': _card.id,
      }),
    );
    await _closeWithAnimation();
  }

  Future<void> _closeWithAnimation() async {
    if (!_closing && mounted) {
      setState(() {
        _closing = true;
      });
    }
    await Future<void>.delayed(_exitDuration);
    await windowManager.close();
  }
}
