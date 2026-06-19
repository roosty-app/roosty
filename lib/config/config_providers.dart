import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'config_repository.dart';
import 'vault_discovery.dart';
import '../core/url_rules.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup.');
});

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return SharedPreferencesConfigRepository(
    ref.watch(sharedPreferencesProvider),
  );
});

final appConfigProvider = FutureProvider<AppConfig>((ref) {
  return ref.watch(configRepositoryProvider).load();
});

final vaultDiscoveryProvider = Provider<VaultDiscovery>((ref) {
  return VaultDiscovery();
});

final vaultCandidatesProvider = FutureProvider<List<VaultCandidate>>((ref) {
  return ref.watch(vaultDiscoveryProvider).discover();
});

final appConfigControllerProvider =
    AsyncNotifierProvider<AppConfigController, AppConfig>(
      AppConfigController.new,
    );

class AppConfigController extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() {
    return ref.watch(configRepositoryProvider).load();
  }

  Future<void> updateVaultPath(String path) async {
    final current = state.value ?? await future;
    await _save(current.copyWith(vaultPath: path.trim()));
  }

  Future<void> updateAndroidVaultUri(String uri) async {
    final current = state.value ?? await future;
    await _save(current.copyWith(androidVaultUri: uri.trim()));
  }

  Future<void> updateClipboardWatchingEnabled(bool enabled) async {
    final current = state.value ?? await future;
    await _save(current.copyWith(clipboardWatchingEnabled: enabled));
  }

  Future<void> addDomainToBlocklist(String domain) async {
    final normalized = normalizeDomain(domain);
    if (normalized == null) {
      return;
    }
    final current = state.value ?? await future;
    final domains = {
      ...current.domainBlocklist.map((value) => normalizeDomain(value)),
      normalized,
    }.whereType<String>().toList()..sort();
    await _save(current.copyWith(domainBlocklist: domains));
  }

  Future<void> removeDomainFromBlocklist(String domain) async {
    final normalized = normalizeDomain(domain);
    if (normalized == null) {
      return;
    }
    final current = state.value ?? await future;
    final domains = current.domainBlocklist
        .map((value) => normalizeDomain(value))
        .whereType<String>()
        .where((value) => value != normalized)
        .toList();
    await _save(current.copyWith(domainBlocklist: domains));
  }

  Future<void> updateLlmConfig(LlmConfig llm) async {
    final current = state.value ?? await future;
    await _save(current.copyWith(llm: llm));
  }

  Future<void> _save(AppConfig config) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(configRepositoryProvider).save(config);
      return config;
    });
  }
}
