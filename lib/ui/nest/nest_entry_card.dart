import 'package:flutter/material.dart';

import '../../core/item.dart';
import '../../theme/tokens.dart';

/// 单条已归巢内容的展示卡。
///
/// 纯展示组件：280 宽，圆角 `tokens.radiusLg`，背景 `tokens.bgCard`，
/// 描边 `tokens.divider`，阴影 `tokens.shadowSm`。左上 source icon，标题
/// 1 行省略，摘要 2 行省略，底部时间用 `tokens.textSecondary`。
class NestEntryCard extends StatelessWidget {
  const NestEntryCard({super.key, required this.item, this.width = 280});

  final Item item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    final textTheme = Theme.of(context).textTheme;

    final title = item.title?.trim().isNotEmpty == true ? item.title! : item.url;
    final summary = item.summary?.trim().isNotEmpty == true
        ? item.summary!
        : item.url;
    final timeLabel = _formatTime(item.capturedAt);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgCard,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(color: tokens.divider),
          boxShadow: tokens.shadowSm,
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    nestSourceIcon(item.source),
                    size: 18,
                    color: tokens.primary,
                  ),
                  SizedBox(width: tokens.space2),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.space2),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
              SizedBox(height: tokens.space3),
              Text(
                timeLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 按 `item.source` 选 icon。沿用 mini card 中的 `_sourceIcon` 逻辑；当前
/// 阶段不重构 mini_card_window，先在 nest 模块内单独维护一份。
IconData nestSourceIcon(String source) {
  return switch (source) {
    'wechat' => Icons.chat_bubble_outline,
    'x' => Icons.alternate_email,
    'xiaohongshu' => Icons.auto_awesome,
    'video' => Icons.play_circle_outline,
    _ => Icons.public,
  };
}

/// 把 `DateTime` 格式化成 `MM-dd HH:mm`（24 小时制）。不依赖 `intl`。
String _formatTime(DateTime t) {
  String two(int v) => v < 10 ? '0$v' : '$v';
  return '${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}
