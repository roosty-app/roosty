import 'package:flutter/material.dart';

import '../core/mini_card.dart';
import '../theme/tokens.dart';

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
    final tokens = context.roostyTokens;
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
          if (card != cards.last) SizedBox(height: tokens.space2),
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
    final tokens = context.roostyTokens;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        key: ValueKey(card.id),
        width: 380,
        height: 200,
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.bgCard,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(color: tokens.divider),
              boxShadow: tokens.shadowMd,
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _sourceIcon(card.item.source),
                        size: 18,
                        color: tokens.primary,
                      ),
                      SizedBox(width: tokens.space2),
                      Expanded(
                        child: Text(
                          'Roosty 看到一条链接',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.space2),
                  _PreviewLine(
                    text: card.item.title,
                    placeholderWidth: 240,
                    style: textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    card.item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                  SizedBox(height: tokens.space2),
                  Expanded(
                    child: _SummaryPreview(
                      text: card.item.summary,
                      failedMessage: card.message,
                    ),
                  ),
                  SizedBox(height: tokens.space2),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            textStyle: textTheme.labelSmall,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.space2,
                            ),
                          ),
                          onPressed: isArchiving ? null : onArchive,
                          icon: const Icon(Icons.archive, size: 16),
                          label: const Text('归巢'),
                        ),
                      ),
                      SizedBox(width: tokens.space1),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: textTheme.labelSmall,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.space1,
                            ),
                          ),
                          onPressed: isArchiving ? null : onIgnoreOnce,
                          child: const Text('忽略一次'),
                        ),
                      ),
                      SizedBox(width: tokens.space1),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: textTheme.labelSmall,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.space1,
                            ),
                          ),
                          onPressed: isArchiving ? null : onBlockDomain,
                          child: const Text('永不归档此域名', maxLines: 1),
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
      return Text(
        text!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
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
    final tokens = context.roostyTokens;
    if (failedMessage != null) {
      return Text(
        failedMessage!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens.error),
      );
    }
    if (text?.trim().isNotEmpty == true) {
      return Text(
        text!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Skeleton(width: 320, height: 12),
        SizedBox(height: tokens.space1),
        const _Skeleton(width: 260, height: 12),
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
    final tokens = context.roostyTokens;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
    );
  }
}
