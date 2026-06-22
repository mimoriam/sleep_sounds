import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final strokeWidth = r * 0.45;
    final rect = Rect.fromCircle(center: center, radius: r - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red (top-left to top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.8, 1.8, false, paint);

    // Yellow (bottom-left to top-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -4.4, 1.6, false, paint);

    // Green (bottom-right to bottom-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.8, false, paint);

    // Blue (top-right to bottom-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.0, 1.8, false, paint);

    // Draw horizontal stem of 'G'
    final stemPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final stemRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      r * 0.85,
      strokeWidth,
    );
    canvas.drawRect(stemRect, stemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
