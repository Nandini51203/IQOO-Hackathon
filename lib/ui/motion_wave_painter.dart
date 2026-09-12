import 'package:flutter/material.dart';

/// Draws the last ~2 seconds of real acceleration-magnitude samples as
/// a single continuous line. This is the one piece of "raw" feedback
/// kept on the main screen — a plain trace rather than numbers — so
/// the person can see the phone is genuinely reading live motion.
class MotionWavePainter extends CustomPainter {
  final List<double> magnitudes;
  final Color color;

  /// Rough scale ceiling for the trace — comfortably above the impact
  /// threshold so a real fall visibly spikes near the top.
  final double scaleMax;

  MotionWavePainter({
    required this.magnitudes,
    required this.color,
    this.scaleMax = 25.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (magnitudes.length - 1);

    for (var i = 0; i < magnitudes.length; i++) {
      final x = i * stepX;
      final normalized = (magnitudes[i] / scaleMax).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MotionWavePainter oldDelegate) => true;
}
