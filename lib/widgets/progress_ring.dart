import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ProgressRing extends StatelessWidget {
  final double percentage; // Le pourcentage à afficher (Ex: 85.0)
  final double size;       // La taille totale du widget en pixels
  final double strokeWidth;// L'épaisseur de la ligne de l'anneau

  const ProgressRing({
    super.key,
    required this.percentage,
    this.size = 80.0,
    this.strokeWidth = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              percentage: percentage,
              strokeWidth: strokeWidth,
              activeColor: AppColors.accentStatus, 
            ),
          ),
          
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              fontSize: size * 0.24, 
              fontWeight: FontWeight.bold,
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color activeColor;

  _ProgressRingPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double sweepAngle = (percentage / 100) * 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.activeColor != activeColor;
  }
}
