import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 空巢状态：自绘的几何巢图 + 引导文案。
///
/// 实现走 design.md §3.1 路径 A（纯 token 化几何）：两条交叉弧线（枝条）
/// 用 `tokens.primary` 描边 + 三个椭圆（蛋）用 `tokens.bgElevated` 填充、
/// `tokens.divider` 描边。双主题靠 token 自动适配，不写死 `Color(0x...)`。
class EmptyNest extends StatelessWidget {
  const EmptyNest({super.key});

  static const String mainText = '还没有内容飞回来';
  static const String subText = '复制一条链接，Roosty 会接住它';

  @override
  Widget build(BuildContext context) {
    final tokens = context.roostyTokens;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 140,
          child: CustomPaint(
            painter: _EmptyNestPainter(
              twigColor: tokens.primary,
              eggFill: tokens.bgElevated,
              eggStroke: tokens.divider,
            ),
          ),
        ),
        SizedBox(height: tokens.space4),
        Text(
          mainText,
          style: textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.space1),
        Text(
          subText,
          style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmptyNestPainter extends CustomPainter {
  _EmptyNestPainter({
    required this.twigColor,
    required this.eggFill,
    required this.eggStroke,
  });

  final Color twigColor;
  final Color eggFill;
  final Color eggStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Twigs: two arcs that cross in the middle to form a nest cradle.
    final twigPaint = Paint()
      ..color = twigColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Twig A: a downward U from upper-left to upper-right.
    final twigA = Path()
      ..moveTo(w * 0.05, h * 0.48)
      ..quadraticBezierTo(w * 0.50, h * 1.05, w * 0.95, h * 0.48);
    canvas.drawPath(twigA, twigPaint);

    // Twig B: a flatter, slightly tilted arc that crosses twig A.
    final twigB = Path()
      ..moveTo(w * 0.12, h * 0.62)
      ..quadraticBezierTo(w * 0.50, h * 0.92, w * 0.88, h * 0.55);
    canvas.drawPath(twigB, twigPaint);

    // Eggs: three ovals resting near the top of the cradle.
    final eggFillPaint = Paint()
      ..color = eggFill
      ..style = PaintingStyle.fill;
    final eggStrokePaint = Paint()
      ..color = eggStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double eggRx = 14;
    const double eggRy = 11;
    final eggCenters = <Offset>[
      Offset(w * 0.32, h * 0.40),
      Offset(w * 0.50, h * 0.34),
      Offset(w * 0.68, h * 0.40),
    ];
    for (final c in eggCenters) {
      final rect = Rect.fromCenter(center: c, width: eggRx * 2, height: eggRy * 2);
      canvas.drawOval(rect, eggFillPaint);
      canvas.drawOval(rect, eggStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyNestPainter oldDelegate) {
    return oldDelegate.twigColor != twigColor ||
        oldDelegate.eggFill != eggFill ||
        oldDelegate.eggStroke != eggStroke;
  }
}
