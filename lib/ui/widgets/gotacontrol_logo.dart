import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GotaControlLogo extends StatelessWidget {
  const GotaControlLogo({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo de GotaControl',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF075B51), Color(0xFF102B3A)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.17),
      child: CustomPaint(painter: _GotaMarkPainter()),
    ),
  );
}

class _GotaMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final drop = Path()
      ..moveTo(width * 0.5, height * 0.02)
      ..cubicTo(width * 0.4, height * 0.19, width * 0.11, height * 0.48, width * 0.11, height * 0.65)
      ..cubicTo(width * 0.11, height * 0.88, width * 0.28, height * 0.99, width * 0.5, height * 0.99)
      ..cubicTo(width * 0.72, height * 0.99, width * 0.89, height * 0.88, width * 0.89, height * 0.65)
      ..cubicTo(width * 0.89, height * 0.48, width * 0.6, height * 0.19, width * 0.5, height * 0.02)
      ..close();
    canvas.drawPath(
      drop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8FFE5), Color(0xFF00E676), Color(0xFF22B8CF)],
        ).createShader(Offset.zero & size),
    );

    final center = Offset(width * 0.5, height * 0.64);
    canvas.drawCircle(
      center,
      width * 0.23,
      Paint()..color = const Color(0xFF10343A),
    );
    canvas.drawCircle(
      center,
      width * 0.23,
      Paint()
        ..color = const Color(0xFFFFD166)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.045,
    );
    final growth = Path()
      ..moveTo(width * 0.37, height * 0.72)
      ..lineTo(width * 0.48, height * 0.61)
      ..lineTo(width * 0.56, height * 0.67)
      ..lineTo(width * 0.68, height * 0.53);
    canvas.drawPath(
      growth,
      Paint()
        ..color = const Color(0xFFFFD166)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.055
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
