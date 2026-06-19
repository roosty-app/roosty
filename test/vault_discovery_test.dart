import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:roosty/config/vault_discovery.dart';

void main() {
  test('discovers a single Windows vault from obsidian.json', () async {
    final temp = await Directory.systemTemp.createTemp('roosty_vaults_');
    addTearDown(() => temp.delete(recursive: true));
    final vault = await Directory(p.join(temp.path, 'Vault')).create();
    final jsonFile = File(p.join(temp.path, 'obsidian.json'));
    await jsonFile.writeAsString(
      jsonEncode({
        'vault-a': {'path': vault.path, 'ts': 10, 'open': true},
      }),
    );

    final candidates = await VaultDiscovery(
      platform: VaultDiscoveryPlatform.windows,
      obsidianJsonPath: jsonFile.path,
    ).discover();

    expect(candidates, hasLength(1));
    expect(candidates.single.id, 'vault-a');
    expect(candidates.single.path, vault.path);
    expect(candidates.single.timestamp, 10);
    expect(candidates.single.isOpen, isTrue);
  });

  test('sorts open vault first, then by timestamp descending', () async {
    final temp = await Directory.systemTemp.createTemp('roosty_vaults_');
    addTearDown(() => temp.delete(recursive: true));
    final openOld = await Directory(p.join(temp.path, 'OpenOld')).create();
    final closedNew = await Directory(p.join(temp.path, 'ClosedNew')).create();
    final closedOld = await Directory(p.join(temp.path, 'ClosedOld')).create();
    final jsonFile = File(p.join(temp.path, 'obsidian.json'));
    await jsonFile.writeAsString(
      jsonEncode({
        'vaults': {
          'closed-old': {'path': closedOld.path, 'ts': 1},
          'closed-new': {'path': closedNew.path, 'ts': 100},
          'open-old': {'path': openOld.path, 'ts': 2, 'open': true},
        },
      }),
    );

    final candidates = await VaultDiscovery(
      platform: VaultDiscoveryPlatform.windows,
      obsidianJsonPath: jsonFile.path,
    ).discover();

    expect(candidates.map((candidate) => candidate.path), [
      openOld.path,
      closedNew.path,
      closedOld.path,
    ]);
  });

  test('returns empty for missing or damaged obsidian.json', () async {
    final temp = await Directory.systemTemp.createTemp('roosty_vaults_');
    addTearDown(() => temp.delete(recursive: true));
    final damaged = File(p.join(temp.path, 'obsidian.json'));
    await damaged.writeAsString('{');

    final damagedCandidates = await VaultDiscovery(
      platform: VaultDiscoveryPlatform.windows,
      obsidianJsonPath: damaged.path,
    ).discover();
    final missingCandidates = await VaultDiscovery(
      platform: VaultDiscoveryPlatform.windows,
      obsidianJsonPath: p.join(temp.path, 'missing.json'),
    ).discover();

    expect(damagedCandidates, isEmpty);
    expect(missingCandidates, isEmpty);
  });

  test('filters vault entries whose directories no longer exist', () async {
    final temp = await Directory.systemTemp.createTemp('roosty_vaults_');
    addTearDown(() => temp.delete(recursive: true));
    final vault = await Directory(p.join(temp.path, 'Vault')).create();
    final jsonFile = File(p.join(temp.path, 'obsidian.json'));
    await jsonFile.writeAsString(
      jsonEncode({
        'valid': {'path': vault.path, 'ts': 2},
        'deleted': {'path': p.join(temp.path, 'Deleted'), 'ts': 10},
      }),
    );

    final candidates = await VaultDiscovery(
      platform: VaultDiscoveryPlatform.windows,
      obsidianJsonPath: jsonFile.path,
    ).discover();

    expect(candidates.map((candidate) => candidate.id), ['valid']);
  });

  test('returns empty on unsupported platforms', () async {
    final candidates = await VaultDiscovery(
      platform: VaultDiscoveryPlatform.other,
    ).discover();

    expect(candidates, isEmpty);
  });
}
