import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

enum VaultDiscoveryPlatform { windows, android, macos, linux, other }

class VaultCandidate {
  const VaultCandidate({
    required this.id,
    required this.path,
    required this.timestamp,
    required this.isOpen,
  });

  final String id;
  final String path;
  final int timestamp;
  final bool isOpen;
}

class VaultDiscovery {
  VaultDiscovery({
    VaultDiscoveryPlatform? platform,
    String? obsidianJsonPath,
    bool Function(String path)? directoryExists,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : _platform = platform ?? _currentPlatform(),
       _obsidianJsonPath = obsidianJsonPath,
       _directoryExists =
           directoryExists ?? ((path) => Directory(path).existsSync()),
       _onError = onError;

  final VaultDiscoveryPlatform _platform;
  final String? _obsidianJsonPath;
  final bool Function(String path) _directoryExists;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  Future<List<VaultCandidate>> discover() async {
    try {
      switch (_platform) {
        case VaultDiscoveryPlatform.windows:
          return await _discoverWindows();
        case VaultDiscoveryPlatform.android:
        case VaultDiscoveryPlatform.macos:
        case VaultDiscoveryPlatform.linux:
        case VaultDiscoveryPlatform.other:
          return const [];
      }
    } catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
      return const [];
    }
  }

  Future<List<VaultCandidate>> _discoverWindows() async {
    final jsonPath = _obsidianJsonPath ?? _windowsObsidianJsonPath();
    if (jsonPath == null) {
      return const [];
    }

    final file = File(jsonPath);
    if (!file.existsSync()) {
      return const [];
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      return const [];
    }

    final candidates = _parseCandidates(decoded);
    candidates.sort(_compareCandidates);
    return candidates;
  }

  List<VaultCandidate> _parseCandidates(Map<dynamic, dynamic> decoded) {
    final vaultsValue = decoded['vaults'];
    final vaults = vaultsValue is Map ? vaultsValue : decoded;
    final candidates = <VaultCandidate>[];

    for (final entry in vaults.entries) {
      final value = entry.value;
      if (value is! Map) {
        continue;
      }

      final pathValue = value['path'];
      if (pathValue is! String) {
        continue;
      }

      final path = pathValue.trim();
      if (path.isEmpty || !_directoryExists(path)) {
        continue;
      }

      candidates.add(
        VaultCandidate(
          id: entry.key.toString(),
          path: path,
          timestamp: _parseTimestamp(value['ts']),
          isOpen: value['open'] == true,
        ),
      );
    }

    return candidates;
  }

  int _parseTimestamp(Object? value) {
    return switch (value) {
      int timestamp => timestamp,
      double timestamp => timestamp.toInt(),
      String timestamp => int.tryParse(timestamp) ?? 0,
      _ => 0,
    };
  }

  int _compareCandidates(VaultCandidate left, VaultCandidate right) {
    if (left.isOpen != right.isOpen) {
      return left.isOpen ? -1 : 1;
    }
    final timestampCompare = right.timestamp.compareTo(left.timestamp);
    if (timestampCompare != 0) {
      return timestampCompare;
    }
    return left.path.compareTo(right.path);
  }

  String? _windowsObsidianJsonPath() {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.trim().isEmpty) {
      return null;
    }
    return p.join(appData, 'obsidian', 'obsidian.json');
  }

  static VaultDiscoveryPlatform _currentPlatform() {
    if (Platform.isWindows) {
      return VaultDiscoveryPlatform.windows;
    }
    if (Platform.isAndroid) {
      return VaultDiscoveryPlatform.android;
    }
    if (Platform.isMacOS) {
      // TODO: macOS Obsidian desktop registry path:
      // ~/Library/Application Support/obsidian/obsidian.json
      return VaultDiscoveryPlatform.macos;
    }
    if (Platform.isLinux) {
      // TODO: Linux Obsidian desktop registry path:
      // ~/.config/obsidian/obsidian.json
      return VaultDiscoveryPlatform.linux;
    }
    return VaultDiscoveryPlatform.other;
  }
}
