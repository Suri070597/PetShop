import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class PetLogo extends StatelessWidget {
  const PetLogo({super.key, this.size = 92, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size.square(size * 0.72),
            painter: _PetBagPainter(),
          ),
          if (showText) ...[
            const SizedBox(height: 4),
            Text(
              'PAW & BAG',
              style: TextStyle(
                color: AppColors.leaf,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.13,
                height: 1,
              ),
            ),
            Text(
              'PET SUPPLIES',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.07,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PetBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bag = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.24,
        size.width * 0.72,
        size.height * 0.62,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(bag, paint);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.02,
        size.width * 0.38,
        size.height * 0.42,
      ),
      3.15,
      3.12,
      false,
      paint,
    );

    final fill = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.fill;

    void oval(double x, double y, double w, double h) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * x,
          size.height * y,
          size.width * w,
          size.height * h,
        ),
        fill,
      );
    }

    oval(0.25, 0.44, 0.16, 0.21);
    oval(0.43, 0.34, 0.15, 0.22);
    oval(0.60, 0.44, 0.16, 0.21);
    oval(0.34, 0.59, 0.33, 0.22);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
