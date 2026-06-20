import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roosty/config/config_providers.dart';
import 'package:roosty/config/vault_discovery.dart';
import 'package:roosty/core/core_providers.dart';
import 'package:roosty/core/item.dart';
import 'package:roosty/main.dart';
import 'package:roosty/sources/clipboard_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tray listener events call window and tray platform methods', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'clipboardWatchingEnabled': true});
    final preferences = await SharedPreferences.getInstance();
    final channels = _PlatformChannels();
    addTearDown(channels.dispose);

    await _pumpApp(tester, preferences);
    await tester.dragUntilVisible(
      find.text('剪贴板监听'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(_clipboardSwitch(tester).value, isTrue);

    await channels.sendTrayEvent('onTrayIconMouseDown');
    await tester.pump();
    expect(channels.windowMethodCount('show'), 1);
    expect(channels.windowMethodCount('focus'), 1);

    await channels.sendTrayEvent('onTrayIconMouseDown');
    await tester.pump();
    expect(channels.windowMethodCount('show'), 2);
    expect(channels.windowMethodCount('focus'), 2);

    await channels.sendTrayEvent('onTrayIconRightMouseDown');
    await tester.pump();
    expect(channels.trayMethodCount('popUpContextMenu'), 1);

    final toggleItem = channels.latestMenuItem('toggle_clipboard');
    expect(toggleItem?['label'], '暂停剪贴板监听');

    await channels.sendTrayEvent('onTrayMenuItemClick', {
      'id': toggleItem!['id'],
    });
    await tester.pump();
    await tester.pump();

    expect(preferences.getBool('clipboardWatchingEnabled'), isTrue);
    expect(_clipboardSwitch(tester).value, isFalse);
    expect(channels.latestMenuItem('toggle_clipboard')?['label'], '恢复剪贴板监听');
  });

  testWidgets(
    'window close and minimize hide the window instead of destroying',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final channels = _PlatformChannels();
      addTearDown(channels.dispose);

      await _pumpApp(tester, preferences);
      channels.clearCalls();

      await channels.sendWindowEvent('close');
      await tester.pump();

      expect(channels.windowMethodCount('hide'), 1);
      expect(channels.windowMethodCount('destroy'), 0);
      expect(
        channels.trayCalls.any(
          (call) =>
              call.method == 'setToolTip' &&
              call.arguments['toolTip'] == 'Roosty 已隐藏到托盘，点托盘图标恢复',
        ),
        isTrue,
      );

      channels.clearCalls();
      await channels.sendWindowEvent('minimize');
      await tester.pump();

      expect(channels.windowMethodCount('hide'), 1);
      expect(channels.windowMethodCount('destroy'), 0);
    },
  );

  testWidgets('settings exit action confirms before destroying the app', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final channels = _PlatformChannels();
    addTearDown(channels.dispose);

    await _pumpApp(tester, preferences);

    await tester.dragUntilVisible(
      find.text('退出 Roosty'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('退出 Roosty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出 Roosty'));
    await tester.pumpAndSettle();

    expect(find.text('退出 Roosty？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(channels.windowMethodCount('destroy'), 0);
    expect(channels.trayMethodCount('destroy'), 0);

    await tester.ensureVisible(find.text('退出 Roosty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出 Roosty'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '退出'));
    await tester.pumpAndSettle();

    expect(channels.trayMethodCount('destroy'), 1);
    expect(channels.windowMethodCount('destroy'), 1);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  SharedPreferences preferences,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        isWindowsProvider.overrideWithValue(true),
        clipboardSourceProvider.overrideWithValue(_EmptyClipboardSource()),
        vaultDiscoveryProvider.overrideWithValue(
          VaultDiscovery(platform: VaultDiscoveryPlatform.other),
        ),
      ],
      child: const RoostyApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

SwitchListTile _clipboardSwitch(WidgetTester tester) {
  return tester.widget<SwitchListTile>(
    find.widgetWithText(SwitchListTile, '剪贴板监听'),
  );
}

class _EmptyClipboardSource extends ClipboardSource {
  @override
  Stream<Item> watch() => const Stream<Item>.empty();
}

class _PlatformChannels {
  _PlatformChannels() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_trayChannel, (call) async {
          trayCalls.add(call);
          if (call.method == 'setContextMenu') {
            menus.add(
              Map<String, dynamic>.from(
                call.arguments['menu'] as Map<dynamic, dynamic>,
              ),
            );
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_windowChannel, (call) async {
          windowCalls.add(call);
          return switch (call.method) {
            'isMinimized' => false,
            'isPreventClose' => true,
            'isVisible' => true,
            'getId' => 1,
            _ => null,
          };
        });
  }

  static const _trayChannel = MethodChannel('tray_manager');
  static const _windowChannel = MethodChannel('window_manager');
  static const _codec = StandardMethodCodec();

  final trayCalls = <MethodCall>[];
  final windowCalls = <MethodCall>[];
  final menus = <Map<String, dynamic>>[];

  void clearCalls() {
    trayCalls.clear();
    windowCalls.clear();
  }

  int trayMethodCount(String method) {
    return trayCalls.where((call) => call.method == method).length;
  }

  int windowMethodCount(String method) {
    return windowCalls.where((call) => call.method == method).length;
  }

  Map<String, dynamic>? latestMenuItem(String key) {
    final menu = menus.lastOrNull;
    if (menu == null) {
      return null;
    }
    final items = (menu['items'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>();
    for (final item in items) {
      if (item['key'] == key) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  Future<void> sendTrayEvent(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'tray_manager',
          _codec.encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );
  }

  Future<void> sendWindowEvent(String eventName) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'window_manager',
          _codec.encodeMethodCall(
            MethodCall('onEvent', {'eventName': eventName}),
          ),
          (_) {},
        );
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_trayChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_windowChannel, null);
  }
}
