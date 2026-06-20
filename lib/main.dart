import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'core/mini_card.dart';
import 'config/config_providers.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';
import 'ui/home_screen.dart';
import 'ui/mini_card_standalone_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (isDesktop) {
    await windowManager.ensureInitialized();
  }
  if (Platform.isWindows) {
    final windowController = await WindowController.fromCurrentEngine();
    final windowArguments = _decodeWindowArguments(windowController.arguments);
    if (windowArguments?['type'] == miniCardWindowType) {
      runApp(
        MiniCardStandaloneApp(
          windowController: windowController,
          initialArguments: MiniCardWindowArguments.fromJson(windowArguments!),
        ),
      );
      return;
    }
  }
  if (isDesktop) {
    await windowManager.setPreventClose(true);
  }
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const RoostyApp(),
    ),
  );
}

Map<String, dynamic>? _decodeWindowArguments(String value) {
  if (value.trim().isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } on FormatException {
    return null;
  }
  return null;
}

class RoostyApp extends StatelessWidget {
  const RoostyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roosty',
      theme: lightRoostyTheme,
      darkTheme: darkRoostyTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
