import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/expression.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_theme.dart';

/// Balança que compara os dois lados da equação em tempo real.
///
/// Cada prato mostra o valor do seu lado ("?" enquanto o lado é inválido). O
/// lado maior desce; quando os valores são iguais a balança se equilibra e
/// muda de cor.
class BalanceScale extends StatelessWidget {
  const BalanceScale({
    super.key,
    required this.left,
    required this.right,
    this.height = 150,
  });

  final double? left;
  final double? right;
  final double height;

  static const double _maxAngle = 0.2; // ~11,5°

  bool get _balanced =>
      left != null && right != null && nearlyEqual(left!, right!);

  double get _targetAngle {
    final l = left, r = right;
    if (l == null || r == null || _balanced) return 0;
    final ratio = (r - l) / (l.abs() + r.abs());
    // Inclinação mínima visível quando os lados diferem por pouco.
    return ratio.sign * (0.35 + 0.65 * ratio.abs()) * _maxAngle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final leftText = left == null ? '?' : formatValue(left!);
    final rightText = right == null ? '?' : formatValue(right!);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '${l10n.leftSide}: $leftText. ${l10n.rightSide}: $rightText.',
      liveRegion: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _targetAngle),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (context, angle, _) => TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: _balanced ? scheme.tertiary : scheme.primary,
            ),
            duration: const Duration(milliseconds: 300),
            builder: (context, accent, _) => CustomPaint(
              painter: _ScalePainter(
                angle: angle,
                leftText: leftText,
                rightText: rightText,
                accent: accent ?? scheme.primary,
                onAccent: _balanced ? scheme.onTertiary : scheme.onPrimary,
                structure: scheme.outline,
                textStyle: mathStyle(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScalePainter extends CustomPainter {
  _ScalePainter({
    required this.angle,
    required this.leftText,
    required this.rightText,
    required this.accent,
    required this.onAccent,
    required this.structure,
    required this.textStyle,
  });

  final double angle;
  final String leftText;
  final String rightText;
  final Color accent;
  final Color onAccent;
  final Color structure;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pivot = Offset(w / 2, h * 0.16);
    final arm = math.min(w * 0.34, 230.0);
    final panWidth = math.min(w * 0.3, 150.0);
    final panHeight = h * 0.3;
    final rope = h * 0.2;

    final line = Paint()
      ..color = structure
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = accent;

    // Coluna e base.
    final baseY = h - 6;
    canvas.drawLine(pivot, Offset(pivot.dx, baseY), line..strokeWidth = 6);
    canvas.drawLine(
      Offset(pivot.dx - 46, baseY),
      Offset(pivot.dx + 46, baseY),
      line..strokeWidth = 8,
    );

    // Travessão.
    final dir = Offset(math.cos(angle), math.sin(angle));
    final leftEnd = pivot - dir * arm;
    final rightEnd = pivot + dir * arm;
    canvas.drawLine(leftEnd, rightEnd, line..strokeWidth = 6);
    canvas.drawCircle(pivot, 9, fill);

    _pan(canvas, leftEnd, leftText, panWidth, panHeight, rope, line, fill);
    _pan(canvas, rightEnd, rightText, panWidth, panHeight, rope, line, fill);
  }

  void _pan(
    Canvas canvas,
    Offset anchor,
    String text,
    double width,
    double height,
    double rope,
    Paint line,
    Paint fill,
  ) {
    final top = anchor.dy + rope;
    final rect = Rect.fromLTWH(anchor.dx - width / 2, top, width, height);
    line.strokeWidth = 2.5;
    canvas.drawLine(anchor, rect.topLeft + const Offset(10, 2), line);
    canvas.drawLine(anchor, rect.topRight + const Offset(-10, 2), line);
    canvas.drawCircle(anchor, 4, fill);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: Radius.circular(height * 0.6),
        bottomRight: Radius.circular(height * 0.6),
      ),
      fill,
    );

    // Valor, reduzido se não couber no prato.
    var fontSize = height * 0.5;
    late TextPainter painter;
    for (var i = 0; i < 6; i++) {
      painter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(fontSize: fontSize, color: onAccent),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width <= width - 24) break;
      fontSize *= 0.85;
    }
    painter.paint(
      canvas,
      rect.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ScalePainter old) =>
      old.angle != angle ||
      old.leftText != leftText ||
      old.rightText != rightText ||
      old.accent != accent ||
      old.onAccent != onAccent ||
      old.structure != structure ||
      old.textStyle != textStyle;
}
