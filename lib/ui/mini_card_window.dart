import 'package:flutter/material.dart';

import '../core/mini_card.dart';

class MiniCardDeck extends StatelessWidget {
  const MiniCardDeck({
    super.key,
    required this.cards,
    required this.isArchiving,
    required this.onArchive,
    required this.onIgnoreOnce,
    required this.onBlockDomain,
  });

  final List<MiniCardModel> cards;
  final bool isArchiving;
  final ValueChanged<String> onArchive;
  final ValueChanged<String> onIgnoreOnce;
  final ValueChanged<String> onBlockDomain;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final card in cards) ...[
          MiniCardWindow(
            card: card,
            isArchiving: isArchiving,
            onArchive: () => onArchive(card.id),
            onIgnoreOnce: () => onIgnoreOnce(card.id),
            onBlockDomain: () => onBlockDomain(card.id),
          ),
          if (card != cards.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class MiniCardWindow extends StatelessWidget {
  const MiniCardWindow({
    super.key,
    required this.card,
    required this.isArchiving,
    required this.onArchive,
    required this.onIgnoreOnce,
    required this.onBlockDomain,
  });

  final MiniCardModel card;
  final bool isArchiving;
  final VoidCallback onArchive;
  final VoidCallback onIgnoreOnce;
  final VoidCallback onBlockDomain;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        key: ValueKey(card.id),
        width: 380,
        height: 200,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_sourceIcon(card.item.source), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Roosty 看到一条链接',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PreviewLine(
                    text: card.item.title,
                    placeholderWidth: 240,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _SummaryPreview(
                      text: card.item.summary,
                      failedMessage: card.message,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isArchiving ? null : onArchive,
                          icon: const Icon(Icons.archive, size: 16),
                          label: const Text('归巢'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextButton(
                          onPressed: isArchiving ? null : onIgnoreOnce,
                          child: const Text('忽略一次'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextButton(
                          onPressed: isArchiving ? null : onBlockDomain,
                          child: const Text('永不归档'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _sourceIcon(String source) {
    return switch (source) {
      'wechat' => Icons.chat_bubble_outline,
      'x' => Icons.alternate_email,
      'xiaohongshu' => Icons.auto_awesome,
      'video' => Icons.play_circle_outline,
      _ => Icons.public,
    };
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.text,
    required this.placeholderWidth,
    this.style,
  });

  final String? text;
  final double placeholderWidth;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (text?.trim().isNotEmpty == true) {
      return Text(text!, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return _Skeleton(width: placeholderWidth, height: 14);
  }
}

class _SummaryPreview extends StatelessWidget {
  const _SummaryPreview({required this.text, required this.failedMessage});

  final String? text;
  final String? failedMessage;

  @override
  Widget build(BuildContext context) {
    if (failedMessage != null) {
      return Text(
        failedMessage!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    if (text?.trim().isNotEmpty == true) {
      return Text(text!, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Skeleton(width: 320, height: 12),
        SizedBox(height: 6),
        _Skeleton(width: 260, height: 12),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
