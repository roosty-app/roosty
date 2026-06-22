import 'package:flutter/material.dart';

import '../../core/item.dart';
import 'empty_nest.dart';
import 'nest_entry_grid.dart';

/// 主体舞台：在空状态（[EmptyNest]）和有内容（[NestEntryGrid]）之间
/// 用 [AnimatedSwitcher] 做 240ms 的交叉淡变。
class NestStage extends StatelessWidget {
  const NestStage({super.key, required this.history});

  final List<Item> history;

  static const Key emptyKey = ValueKey('NestStage.empty');
  static const Key gridKey = ValueKey('NestStage.grid');

  @override
  Widget build(BuildContext context) {
    final isEmpty = history.isEmpty;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: isEmpty
          ? const Align(
              key: emptyKey,
              alignment: Alignment.topCenter,
              child: EmptyNest(),
            )
          : Align(
              key: gridKey,
              alignment: Alignment.topLeft,
              child: NestEntryGrid(items: history),
            ),
    );
  }
}
