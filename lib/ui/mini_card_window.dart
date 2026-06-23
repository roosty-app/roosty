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
          _MiniCardEntryAnimator(
            key: ValueKey('mini-card-entry-${card.id}'),
            child: MiniCardWindow(
              card: card,
              isArchiving: isArchiving,
              onArchive: () => onArchive(card.id),
              onIgnoreOnce: () => onIgnoreOnce(card.id),
              onBlockDomain: () => onBlockDomain(card.id),
            ),
          ),
          if (card != cards.last) SizedBox(height: tokens.space2),
        ],
      ],
    );
  }
}

/// Plays a one-shot slide-in + fade-in when a card joins the deck.
///
/// Resting position is `Offset.zero`; entry starts from 24px below-right
/// to convey "鸟落枝" arrival per design.md §4. The animation runs once
/// per mount because [TweenAnimationBuilder] only re-animates when the
/// tween end value changes.
class _MiniCardEntryAnimator extends StatelessWidget {
  const _MiniCardEntryAnimator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, animatedChild) {
        final progress = (1 - t) * 24;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(progress, progress),
            child: animatedChild,
          ),
        );
      },
      child: child,
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
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: _buildSwitcherTransition,
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
                      _SourceIconBadge(source: card.item.source),
                      SizedBox(width: tokens.space2),
                      Expanded(
                        child: Text(
                          '一只链接落到了枝头',
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
                          icon: const Icon(Icons.arrow_outward, size: 16),
                          label: const Text('飞回巢'),
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

  /// Direction-aware transition for the inner [AnimatedSwitcher].
  ///
  /// Entry (status forward / completed): handled by the outer
  /// [_MiniCardEntryAnimator]; this builder returns the child unchanged so
  /// the two layers do not stack into a double animation on first mount.
  ///
  /// Exit (status reverse / dismissed): slide toward the bottom-right (the
  /// default Windows tray position), shrink to 0.3, and fade — the same
  /// "card flies into the tray" sequence the standalone window uses. The
  /// in-app deck does not have an exact tray vector available, so the
  /// direction is the conservative fallback used elsewhere.
  Widget _buildSwitcherTransition(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, animatedChild) {
        final status = animation.status;
        final isExit =
            status == AnimationStatus.reverse ||
            status == AnimationStatus.dismissed;
        if (!isExit) {
          return animatedChild!;
        }
        final t = animation.value.clamp(0.0, 1.0);
        // `t` runs from 1 -> 0 on reverse; convert to exit progress.
        final progress = 1.0 - t;
        const flight = Offset(200, 200);
        final scale = 1.0 - 0.7 * progress;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: flight * progress,
            child: Transform.scale(
              scale: scale,
              child: animatedChild,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Round badge that frames the source icon with a [primarySubtle] disc,
/// giving the title row a "鸟落枝" anchor per design.md §3.4.
class _SourceIconBadge extends StatelessWidget {
  const _SourceIconBadge({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.primarySubtle,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _sourceIconFor(source),
        size: 18,
        color: tokens.primary,
      ),
    );
  }

  static IconData _sourceIconFor(String source) {
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
