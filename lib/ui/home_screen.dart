import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Roosty')),
      body: Center(
        child: appConfig.when(
          data: (config) => Text(
            config.vaultPath == null ? '准备归巢' : 'Vault 已就绪',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => const Text('配置加载失败'),
        ),
      ),
    );
  }
}
