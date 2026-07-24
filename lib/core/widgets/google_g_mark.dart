import 'package:flutter/material.dart';

/// Marca “G” do Google (4 cores) para botão de login.
class GoogleGMark extends StatelessWidget {
  const GoogleGMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final stroke = s * 0.18;
    final radius = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Arcos do “G” (sentido horário a partir da direita).
    paint.color = blue;
    canvas.drawArc(rect, -0.35, 1.55, false, paint);
    paint.color = green;
    canvas.drawArc(rect, 1.2, 1.0, false, paint);
    paint.color = yellow;
    canvas.drawArc(rect, 2.2, 0.85, false, paint);
    paint.color = red;
    canvas.drawArc(rect, 3.05, 1.15, false, paint);

    // Barra horizontal do G.
    final bar = Paint()
      ..style = PaintingStyle.fill
      ..color = blue;
    final barH = stroke * 0.95;
    final barLeft = cx - radius * 0.08;
    final barRight = cx + radius;
    canvas.drawRRect(
      RRect.fromLTRBR(
        barLeft,
        cy - barH / 2,
        barRight,
        cy + barH / 2,
        Radius.circular(barH / 4),
      ),
      bar,
    );

    // Cobre a junção da barra com o arco azul.
    canvas.drawArc(
      rect,
      -0.2,
      0.55,
      false,
      paint..color = blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
