import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/core/mini_card.dart';
import 'package:roosty/sources/clipboard_source.dart';
import 'package:roosty/ui/desktop_mini_card_window_host.dart';
import 'package:roosty/ui/desktop_tray_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flashTrayIcon toggles the tray icon multiple times within 500ms',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final channels = _TrayChannelSpy();
    addTearDown(channels.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          isWindowsProvider.overrideWithValue(true),
          clipboardSourceProvider.overrideWithValue(_EmptyClipboardSource()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DesktopTrayBridge()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    channels.setIconCalls.clear();

    // 500ms / (2 blinks * 2 steps) = 125ms per tick; the initial apply runs
    // immediately, so we expect 1 + 4 = 5 setIcon calls by the time the
    // restore timer fires at 500ms.
    unawaited(TrayController.instance.flashTrayIcon());
    await tester.pump();
    expect(channels.setIconCalls.length, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(milliseconds: 125));
    await tester.pump(const Duration(milliseconds: 125));
    await tester.pump(const Duration(milliseconds: 125));
    await tester.pump(const Duration(milliseconds: 125));

    // Initial frame plus 4 periodic ticks plus the final restore call.
    expect(channels.setIconCalls.length, greaterThanOrEqualTo(5));
  });

  testWidgets(
      'mini card action channel triggers tray flash for archive, ignore, and block',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final channels = _TrayChannelSpy();
    addTearDown(channels.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          isWindowsProvider.overrideWithValue(true),
          clipboardSourceProvider.overrideWithValue(_EmptyClipboardSource()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DesktopTrayBridge(),
                DesktopMiniCardWindowHost(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Three independent dismiss paths share the same flash hook; we drive
    // the action channel directly because the host is the only place all
    // three exits funnel through.
    for (final action in const ['archive', 'ignoreOnce', 'blockDomain']) {
      channels.setIconCalls.clear();
      await channels.sendAction(action, 'card-$action');
      await tester.pump();
      expect(
        channels.setIconCalls,
        isNotEmpty,
        reason: 'expected flashTrayIcon to fire for action=$action',
      );
      // Drain the periodic timer so it does not leak across iterations.
      await tester.pump(const Duration(milliseconds: 600));
    }
  });
}

class _EmptyClipboardSource extends ClipboardSource {
  @override
  Stream<Item> watch() => const Stream<Item>.empty();
}

class _TrayChannelSpy {
  _TrayChannelSpy() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_trayChannel, (call) async {
      if (call.method == 'setIcon') {
        setIconCalls.add(call);
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_windowChannel, (call) async {
      return switch (call.method) {
        'isPreventClose' => true,
        'isVisible' => true,
        'isMinimized' => false,
        'getId' => 1,
        _ => null,
      };
    });
    // Acknowledge channel registration so the host's `_handleAction` becomes
    // reachable through the simulated multi-window router.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_multiWindowMethodChannel, (call) async {
      return null;
    });
  }

  static const _trayChannel = MethodChannel('tray_manager');
  static const _windowChannel = MethodChannel('window_manager');
  static const _multiWindowMethodChannel = MethodChannel(
    'mixin.one/desktop_multi_window/channels',
  );
  static const _multiWindowChannel = 'mixin.one/desktop_multi_window/channels';
  static const _actionChannel = 'roosty/mini_card_actions';
  static const _codec = StandardMethodCodec();

  final List<MethodCall> setIconCalls = <MethodCall>[];

  Future<void> sendAction(String action, String cardId) async {
    // The multi-window channel router dispatches a `methodCall` envelope to
    // the handler registered for the named channel (see
    // desktop_multi_window/window_channel.dart `_initializeChannelManager`).
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      _multiWindowChannel,
      _codec.encodeMethodCall(
        MethodCall('methodCall', {
          'channel': _actionChannel,
          'method': miniCardActionMethod,
          'arguments': {
            'action': action,
            'cardId': cardId,
          },
        }),
      ),
      (_) {},
    );
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_trayChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_windowChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_multiWindowMethodChannel, null);
  }
}
