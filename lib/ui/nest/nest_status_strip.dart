import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 巢穴状态条：vault icon + 名称 / 监听灯 / 今日 N 条归巢。
///
/// 纯展示组件，不读 provider，由父级（NestHeader）注入数据。颜色全部走
/// `RoostyTokens`，用于在 light/dark 主题下正确切换。
class NestStatusStrip extends StatelessWidget {
  const NestStatusStrip({
    super.key,
    required this.vaultName,
    required this.isWatching,
    required this.todayCount,
  });

  /// vault 名（通常是路径最后一级目录名）。空表示未连接。
  final String vaultName;

  /// 剪贴板监听是否生效。
  final bool isWatching;

  /// 今日已归巢条数。
  final int todayCount;

  /// 监听灯 dot 的 widget key，便于 widget test 断言颜色。
  static const Key watchDotKey = ValueKey('NestStatusStrip.watchDot');

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    final textTheme = Theme.of(context).textTheme;
    final segmentStyle = textTheme.bodySmall?.copyWith(
      color: tokens.textSecondary,
    );
    final hasVault = vaultName.trim().isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.account_tree_outlined,
          size: 14,
          color: tokens.textSecondary,
        ),
        SizedBox(width: tokens.space1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            hasVault ? vaultName : '未连接',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: segmentStyle,
          ),
        ),
        _Separator(style: segmentStyle, hPad: tokens.space2),
        Container(
          key: watchDotKey,
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isWatching ? tokens.success : tokens.textDisabled,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: tokens.space1),
        Text(
          isWatching ? '监听中' : '未监听',
          style: segmentStyle,
        ),
        _Separator(style: segmentStyle, hPad: tokens.space2),
        Icon(Icons.egg_outlined, size: 14, color: tokens.primary),
        SizedBox(width: tokens.space1),
        Text(
          '今日 $todayCount 条归巢',
          style: segmentStyle,
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.style, required this.hPad});

  final TextStyle? style;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Text('·', style: style),
    );
  }
}
