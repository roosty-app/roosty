import 'package:flutter/material.dart';

import '../../core/item.dart';
import '../../theme/tokens.dart';
import 'nest_entry_card.dart';

/// 多条已归巢内容的网格容器。
///
/// 用 `Wrap` 把每条 [Item] 渲染为 [NestEntryCard]，最多展示 [maxVisible] 条；
/// 超出时底部出现 `查看全部 N 条` 的 `TextButton`（Phase 2 中暂无副作用）。
class NestEntryGrid extends StatelessWidget {
  const NestEntryGrid({
    super.key,
    required this.items,
    this.maxVisible = 6,
  });

  final List<Item> items;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    final visible = items.length > maxVisible
        ? items.sublist(0, maxVisible)
        : items;
    final overflow = items.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: tokens.space2,
          runSpacing: tokens.space2,
          children: [
            for (final item in visible) NestEntryCard(item: item),
          ],
        ),
        if (overflow > 0) ...[
          SizedBox(height: tokens.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              // Phase 2: no callback wired; later phase opens a full list.
              onPressed: () {},
              child: Text('查看全部 ${items.length} 条'),
            ),
          ),
        ],
      ],
    );
  }
}
