import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Faixa estilo Matrix exibida durante o tick de atualização online.
class MatrixRefreshBar extends StatefulWidget {
  const MatrixRefreshBar({
    super.key,
    this.height = 14,
    this.duration = const Duration(milliseconds: 750),
  });

  final double height;
  final Duration duration;

  @override
  State<MatrixRefreshBar> createState() => _MatrixRefreshBarState();
}

class _MatrixRefreshBarState extends State<MatrixRefreshBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_MatrixColumn> _columns;
  static const _chars = '01GSアイウエオカキクケコシスセソ';

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _columns = List.generate(
      28,
      (i) => _MatrixColumn(
        speed: 0.55 + rng.nextDouble() * 0.9,
        phase: rng.nextDouble(),
        charOffset: rng.nextInt(_chars.length),
      ),
    );
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.92),
          border: Border.all(
            color: AppColors.trustHigh.withValues(alpha: 0.22),
          ),
        ),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _MatrixRainPainter(
                  progress: _controller.value,
                  columns: _columns,
                  chars: _chars,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatrixColumn {
  const _MatrixColumn({
    required this.speed,
    required this.phase,
    required this.charOffset,
  });

  final double speed;
  final double phase;
  final int charOffset;
}

class _MatrixRainPainter extends CustomPainter {
  _MatrixRainPainter({
    required this.progress,
    required this.columns,
    required this.chars,
  });

  final double progress;
  final List<_MatrixColumn> columns;
  final String chars;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final colWidth = size.width / columns.length;
    final fontSize = math.min(9.0, size.height - 2);

    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final x = i * colWidth + colWidth * 0.15;
      final headY =
          (((progress * col.speed) + col.phase) % 1.15) * (size.height + 8) - 6;

      for (var t = 0; t < 3; t++) {
        final y = headY - t * (fontSize * 0.85);
        if (y < -fontSize || y > size.height) continue;

        final char = chars[(col.charOffset + i + t) % chars.length];
        final opacity = t == 0 ? 1.0 : (0.45 - t * 0.14);
        if (opacity <= 0) continue;

        final color = t == 0
            ? AppColors.trustHigh
            : AppColors.trustHigh.withValues(alpha: opacity);

        final painter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontFamily: 'monospace',
              fontWeight: t == 0 ? FontWeight.w700 : FontWeight.w500,
              shadows: t == 0
                  ? [
                      Shadow(
                        color: AppColors.trustHigh.withValues(alpha: 0.65),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(canvas, Offset(x, y));
      }
    }

    final scanY = progress * size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.trustHigh.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 2, size.width, 4),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
