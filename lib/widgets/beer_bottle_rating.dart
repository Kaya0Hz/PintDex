import 'package:beer_tracker/models/beer_entry.dart';
import 'package:flutter/material.dart';

class BeerBottleRating extends StatelessWidget {
  const BeerBottleRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 34,
    this.spacing = 8,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.tertiary;
    final inactive = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(beerRatingMax, (index) {
        final bottleValue = index + 1;
        final selected = bottleValue <= value;
        return Padding(
          padding: EdgeInsets.only(right: index == beerRatingMax - 1 ? 0 : spacing),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(bottleValue),
            child: SizedBox(
              width: size,
              height: size * 1.25,
              child: CustomPaint(
                painter: _BottlePainter(
                  fillColor: selected ? active : Colors.transparent,
                  strokeColor: selected ? active : inactive,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BottlePainter extends CustomPainter {
  const _BottlePainter({required this.fillColor, required this.strokeColor});

  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final glassLeft = size.width * 0.2;
    final glassRight = size.width * 0.7;
    final glassTop = size.height * 0.18;
    final glassBottom = size.height * 0.9;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.black;

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = strokeColor.withValues(alpha: 0.18);

    final glassPath = Path()
      ..moveTo(glassLeft, glassTop)
      ..lineTo(glassRight, glassTop)
      ..lineTo(glassRight, glassBottom)
      ..lineTo(glassLeft, glassBottom)
      ..close();

    final foamPath = Path()
      ..moveTo(glassLeft, glassTop)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.1, size.width * 0.34, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.06, size.width * 0.5, size.height * 0.17)
      ..quadraticBezierTo(size.width * 0.58, size.height * 0.08, glassRight, glassTop)
      ..close();

    final handlePath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.3, size.width * 0.92, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.74, size.width * 0.7, size.height * 0.74)
      ..lineTo(size.width * 0.7, size.height * 0.66)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.66, size.width * 0.82, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.38, size.width * 0.7, size.height * 0.38)
      ..close();

    canvas.drawPath(glassPath, fillPaint);
    canvas.drawPath(handlePath, fillPaint);
    canvas.drawPath(foamPath, fillPaint);
    canvas.drawPath(glassPath, shadowPaint);
    canvas.drawPath(handlePath, shadowPaint);
    canvas.drawPath(foamPath, shadowPaint);
    canvas.drawPath(glassPath, strokePaint);
    canvas.drawPath(handlePath, strokePaint);
    canvas.drawPath(foamPath, strokePaint);

    final glassHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.45);
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.24),
      Offset(size.width * 0.4, size.height * 0.82),
      glassHighlight,
    );
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor || oldDelegate.strokeColor != strokeColor;
  }
}
