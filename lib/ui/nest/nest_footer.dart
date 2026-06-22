import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 收尾的退出按钮条：右下角的 `TextButton.icon`。
///
/// 按 design.md §1.2 / 锁定决策："退出 Roosty" 常驻可见，不藏在折叠面板里。
class NestFooter extends StatelessWidget {
  const NestFooter({super.key, required this.onExitApp});

  /// 用户点击「退出 Roosty」时透传给外部的回调。
  final VoidCallback onExitApp;

  static const Key exitButtonKey = ValueKey('NestFooter.exitButton');
  static const String exitLabel = '退出 Roosty';

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    return SizedBox(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space2),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: exitButtonKey,
            style: TextButton.styleFrom(foregroundColor: tokens.error),
            onPressed: onExitApp,
            icon: const Icon(Icons.power_settings_new),
            label: const Text(exitLabel),
          ),
        ),
      ),
    );
  }
}
