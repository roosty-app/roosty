import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/core_providers.dart';
import '../../theme/tokens.dart';

/// 折叠的设置面板：把原本平铺的 Vault / AI 摘要 / 捕获 / 忽略列表四个 Section
/// 收纳到一个 [ExpansionTile] 中。
///
/// - 默认收起（`forceExpanded=false`）。
/// - 当 vault 未配置时由父级把 `forceExpanded` 设为 `true`，初始展开方便引导。
/// - 不创建新的 provider；所有 controller / config / 回调都通过 props 注入，
///   保持与 `_HomeContent` 同一套 prop-drilling 模式。
class NestSettings extends StatelessWidget {
  const NestSettings({
    super.key,
    required this.config,
    required this.effectiveClipboardWatching,
    required this.captureState,
    required this.vaultPathController,
    required this.llmBaseUrlController,
    required this.llmApiKeyController,
    required this.llmModelController,
    required this.manualUrlController,
    required this.forceExpanded,
    required this.onChooseVault,
    required this.onSaveVault,
    required this.onRediscoverVaults,
    required this.onSaveLlm,
    required this.onRemoveBlockedDomain,
    required this.onToggleClipboard,
    required this.onManualArchive,
  });

  final AppConfig config;
  final bool effectiveClipboardWatching;
  final CaptureState captureState;
  final TextEditingController vaultPathController;
  final TextEditingController llmBaseUrlController;
  final TextEditingController llmApiKeyController;
  final TextEditingController llmModelController;
  final TextEditingController manualUrlController;

  /// 父级根据 vault 是否配置决定是否强制初始展开。
  final bool forceExpanded;

  final VoidCallback onChooseVault;
  final VoidCallback onSaveVault;
  final VoidCallback onRediscoverVaults;
  final VoidCallback onSaveLlm;
  final ValueChanged<String> onRemoveBlockedDomain;
  final ValueChanged<bool> onToggleClipboard;
  final VoidCallback onManualArchive;

  static const Key headerKey = ValueKey('NestSettings.header');
  static const Key bodyKey = ValueKey('NestSettings.body');

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgCard,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: tokens.divider),
        boxShadow: tokens.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        // Suppress ExpansionTile's default top/bottom Material dividers; the
        // surrounding DecoratedBox already provides borders.
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('NestSettings.expansion'),
            initiallyExpanded: forceExpanded,
            tilePadding: EdgeInsets.symmetric(
              horizontal: tokens.space4,
              vertical: tokens.space1,
            ),
            childrenPadding: EdgeInsets.fromLTRB(
              tokens.space4,
              0,
              tokens.space4,
              tokens.space4,
            ),
            leading: Icon(Icons.tune, color: tokens.textPrimary),
            iconColor: tokens.textPrimary,
            collapsedIconColor: tokens.textSecondary,
            title: Text(
              '设置',
              key: headerKey,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              KeyedSubtree(
                key: bodyKey,
                child: _SettingsBody(
                  tokens: tokens,
                  config: config,
                  effectiveClipboardWatching: effectiveClipboardWatching,
                  captureState: captureState,
                  vaultPathController: vaultPathController,
                  llmBaseUrlController: llmBaseUrlController,
                  llmApiKeyController: llmApiKeyController,
                  llmModelController: llmModelController,
                  manualUrlController: manualUrlController,
                  onChooseVault: onChooseVault,
                  onSaveVault: onSaveVault,
                  onRediscoverVaults: onRediscoverVaults,
                  onSaveLlm: onSaveLlm,
                  onRemoveBlockedDomain: onRemoveBlockedDomain,
                  onToggleClipboard: onToggleClipboard,
                  onManualArchive: onManualArchive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.tokens,
    required this.config,
    required this.effectiveClipboardWatching,
    required this.captureState,
    required this.vaultPathController,
    required this.llmBaseUrlController,
    required this.llmApiKeyController,
    required this.llmModelController,
    required this.manualUrlController,
    required this.onChooseVault,
    required this.onSaveVault,
    required this.onRediscoverVaults,
    required this.onSaveLlm,
    required this.onRemoveBlockedDomain,
    required this.onToggleClipboard,
    required this.onManualArchive,
  });

  final RoostyTokens tokens;
  final AppConfig config;
  final bool effectiveClipboardWatching;
  final CaptureState captureState;
  final TextEditingController vaultPathController;
  final TextEditingController llmBaseUrlController;
  final TextEditingController llmApiKeyController;
  final TextEditingController llmModelController;
  final TextEditingController manualUrlController;
  final VoidCallback onChooseVault;
  final VoidCallback onSaveVault;
  final VoidCallback onRediscoverVaults;
  final VoidCallback onSaveLlm;
  final ValueChanged<String> onRemoveBlockedDomain;
  final ValueChanged<bool> onToggleClipboard;
  final VoidCallback onManualArchive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubsectionLabel(text: 'Vault', tokens: tokens),
        SizedBox(height: tokens.space2),
        _VaultRow(
          tokens: tokens,
          controller: vaultPathController,
          onChoose: onChooseVault,
          onSave: onSaveVault,
          onRediscover: onRediscoverVaults,
        ),
        SizedBox(height: tokens.space6),
        _SubsectionLabel(text: 'AI 摘要', tokens: tokens),
        SizedBox(height: tokens.space2),
        _LlmFields(
          tokens: tokens,
          baseUrlController: llmBaseUrlController,
          apiKeyController: llmApiKeyController,
          modelController: llmModelController,
          onSave: onSaveLlm,
        ),
        SizedBox(height: tokens.space6),
        _SubsectionLabel(text: '捕获', tokens: tokens),
        SizedBox(height: tokens.space2),
        _CaptureSection(
          tokens: tokens,
          effectiveClipboardWatching: effectiveClipboardWatching,
          captureState: captureState,
          manualUrlController: manualUrlController,
          onToggleClipboard: onToggleClipboard,
          onManualArchive: onManualArchive,
        ),
        SizedBox(height: tokens.space6),
        _SubsectionLabel(text: '忽略列表', tokens: tokens),
        SizedBox(height: tokens.space2),
        _BlocklistSection(
          tokens: tokens,
          domains: config.domainBlocklist,
          onRemove: onRemoveBlockedDomain,
        ),
      ],
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel({required this.text, required this.tokens});

  final String text;
  final RoostyTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _VaultRow extends StatelessWidget {
  const _VaultRow({
    required this.tokens,
    required this.controller,
    required this.onChoose,
    required this.onSave,
    required this.onRediscover,
  });

  final RoostyTokens tokens;
  final TextEditingController controller;
  final VoidCallback onChoose;
  final VoidCallback onSave;
  final VoidCallback onRediscover;

  @override
  Widget build(BuildContext context) {
    // Desktop-only branch: isAndroidProvider is frozen / always false on
    // desktop (see DECISIONS.md), so the prior Android SAF branch is removed
    // here for clarity.
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Obsidian vault 目录',
            ),
            onSubmitted: (_) => onSave(),
          ),
        ),
        SizedBox(width: tokens.space2),
        IconButton.filledTonal(
          tooltip: '选择目录',
          onPressed: onChoose,
          icon: const Icon(Icons.folder_open),
        ),
        SizedBox(width: tokens.space2),
        IconButton.outlined(
          tooltip: '重新检测 Obsidian 库',
          onPressed: onRediscover,
          icon: const Icon(Icons.refresh),
        ),
        SizedBox(width: tokens.space2),
        IconButton.filled(
          tooltip: '保存',
          onPressed: onSave,
          icon: const Icon(Icons.save),
        ),
      ],
    );
  }
}

class _LlmFields extends StatelessWidget {
  const _LlmFields({
    required this.tokens,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.onSave,
  });

  final RoostyTokens tokens;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: baseUrlController,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            hintText: 'https://api.deepseek.com',
          ),
          onSubmitted: (_) => onSave(),
        ),
        SizedBox(height: tokens.space3),
        TextField(
          controller: apiKeyController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'API Key'),
          onSubmitted: (_) => onSave(),
        ),
        SizedBox(height: tokens.space3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: '模型',
                  hintText: 'deepseek-chat',
                ),
                onSubmitted: (_) => onSave(),
              ),
            ),
            SizedBox(width: tokens.space2),
            IconButton.filled(
              tooltip: '保存 AI 设置',
              onPressed: onSave,
              icon: const Icon(Icons.save),
            ),
          ],
        ),
      ],
    );
  }
}

class _CaptureSection extends StatelessWidget {
  const _CaptureSection({
    required this.tokens,
    required this.effectiveClipboardWatching,
    required this.captureState,
    required this.manualUrlController,
    required this.onToggleClipboard,
    required this.onManualArchive,
  });

  final RoostyTokens tokens;
  final bool effectiveClipboardWatching;
  final CaptureState captureState;
  final TextEditingController manualUrlController;
  final ValueChanged<bool> onToggleClipboard;
  final VoidCallback onManualArchive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('剪贴板监听'),
          value: effectiveClipboardWatching,
          onChanged: onToggleClipboard,
          secondary: const Icon(Icons.content_paste_search),
        ),
        SizedBox(height: tokens.space3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: manualUrlController,
                decoration: const InputDecoration(
                  labelText: '手动粘贴 URL',
                ),
                onSubmitted: (_) => onManualArchive(),
              ),
            ),
            SizedBox(width: tokens.space2),
            IconButton.filled(
              tooltip: '归巢',
              onPressed: captureState.isArchiving ? null : onManualArchive,
              icon: const Icon(Icons.archive),
            ),
          ],
        ),
      ],
    );
  }
}

class _BlocklistSection extends StatelessWidget {
  const _BlocklistSection({
    required this.tokens,
    required this.domains,
    required this.onRemove,
  });

  final RoostyTokens tokens;
  final List<String> domains;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (domains.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgElevated,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space4,
            vertical: tokens.space3,
          ),
          child: Text(
            '暂无忽略域名',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final domain in domains)
          _BlockedDomainTile(
            domain: domain,
            onRemove: () => onRemove(domain),
          ),
      ],
    );
  }
}

class _BlockedDomainTile extends StatelessWidget {
  const _BlockedDomainTile({required this.domain, required this.onRemove});

  final String domain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.divider)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.block, color: tokens.textSecondary),
        title: Text(domain, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: '移除',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}
