import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../config/config_providers.dart';
import '../../core/core_providers.dart';
import '../../core/item.dart';
import '../../theme/text_theme.dart';
import '../../theme/tokens.dart';
import 'nest_status_strip.dart';

/// 顶部品牌区：左侧标识 + tagline，右侧巢穴状态条。
///
/// 数据自取：
/// - vault path 来自 [appConfigControllerProvider]，未配置时显示"未连接"。
/// - 监听状态来自 [effectiveClipboardWatchingProvider]。
/// - 今日归巢计数从 [captureControllerProvider] 的 history 按当天过滤得出。
class NestHeader extends ConsumerWidget {
  const NestHeader({super.key});

  static const double height = 140;
  static const String tagline = '把散落的内容叼回知识库';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.roostyTokens;
    final config = ref.watch(appConfigControllerProvider).value;
    final isWatching = ref.watch(effectiveClipboardWatchingProvider);
    final history = ref.watch(captureControllerProvider).history;

    final vaultName = _shortVaultName(config?.vaultPath);
    final todayCount = _countToday(history);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space6,
        vertical: tokens.space4,
      ),
      decoration: BoxDecoration(
        color: tokens.bgBase,
        border: Border(
          bottom: BorderSide(color: tokens.divider),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _BrandBlock(tokens: tokens),
            ),
            SizedBox(width: tokens.space4),
            NestStatusStrip(
              vaultName: vaultName,
              isWatching: isWatching,
              todayCount: todayCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.tokens});

  final RoostyTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Roosty',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: roostyLatinDisplayFontFamily,
            fontFamilyFallback: const [roostySerifFontFamily],
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.1,
            letterSpacing: 0.2,
            color: tokens.textPrimary,
          ),
        ),
        SizedBox(height: tokens.space1),
        Text(
          NestHeader.tagline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: roostySerifFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 把 vault 路径压成短名（最后一级目录），跨 Windows/POSIX 风格。
String _shortVaultName(String? rawPath) {
  final path = rawPath?.trim() ?? '';
  if (path.isEmpty) {
    return '';
  }
  // path 包内置 basename 处理多平台分隔符；如果传入是 URI 风格也能拿末段。
  final basename = p.basename(path);
  if (basename.isNotEmpty) {
    return basename;
  }
  // 兜底：极端情况下 basename 为空（比如纯分隔符），保留原路径前 16 字符。
  return path.length > 16 ? '${path.substring(0, 16)}…' : path;
}

/// 统计 [history] 中归档时间为「今天」的条目数。
int _countToday(List<Item> history) {
  if (history.isEmpty) {
    return 0;
  }
  final now = DateTime.now();
  var count = 0;
  for (final item in history) {
    final at = item.capturedAt;
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      count++;
    }
  }
  return count;
}
