import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Intensidade do pulso — repouso contínuo ou pico no refresh.
enum MatrixRefreshIntensity {
  ambient,
  active,
}

/// Faixa de pulso estilo eletrocardiograma — sempre viva no rodapé do Centro.
class MatrixRefreshBar extends StatefulWidget {
  const MatrixRefreshBar({
    super.key,
    this.height = 14,
    this.intensity = MatrixRefreshIntensity.ambient,
  });

  final double height;
  final MatrixRefreshIntensity intensity;

  @override
  State<MatrixRefreshBar> createState() => _MatrixRefreshBarState();
}

class _MatrixRefreshBarState extends State<MatrixRefreshBar>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: _waveDurationFor(widget.intensity),
    )..repeat();
    _sweepController = AnimationController(
      vsync: this,
      duration: _sweepDurationFor(widget.intensity),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MatrixRefreshBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity) {
      _waveController
        ..duration = _waveDurationFor(widget.intensity)
        ..repeat();
      _sweepController
        ..duration = _sweepDurationFor(widget.intensity)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  /// Onda principal (batimentos) — mais lenta para leitura calma.
  Duration _waveDurationFor(MatrixRefreshIntensity intensity) =>
      switch (intensity) {
        MatrixRefreshIntensity.ambient => const Duration(milliseconds: 4200),
        MatrixRefreshIntensity.active => const Duration(milliseconds: 1200),
      };

  /// Varredura do monitor — ritmo atual, preservado.
  Duration _sweepDurationFor(MatrixRefreshIntensity intensity) =>
      switch (intensity) {
        MatrixRefreshIntensity.ambient => const Duration(milliseconds: 2400),
        MatrixRefreshIntensity.active => const Duration(milliseconds: 900),
      };

  @override
  Widget build(BuildContext context) {
    final active = widget.intensity == MatrixRefreshIntensity.active;
    final borderAlpha = active ? 0.42 : 0.18;
    final bgAlpha = active ? 0.96 : 0.9;

    return AnimatedContainer(
      duration:  Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: bgAlpha),
            border: Border.all(
              color: AppColors.trustHigh.withValues(alpha: borderAlpha),
            ),
          ),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: Listenable.merge([_waveController, _sweepController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _EcgPulsePainter(
                    waveProgress: _waveController.value,
                    sweepProgress: _sweepController.value,
                    intensity: widget.intensity,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EcgPulsePainter extends CustomPainter {
  _EcgPulsePainter({
    required this.waveProgress,
    required this.sweepProgress,
    required this.intensity,
  });

  final double waveProgress;
  final double sweepProgress;
  final MatrixRefreshIntensity intensity;

  bool get _active => intensity == MatrixRefreshIntensity.active;

  /// Amostra normalizada [-1, 1] de um batimento sintético.
  static double _beatSample(double phase) {
    if (phase < 0.62) return 0;
    if (phase < 0.66) return -0.18;
    if (phase < 0.69) return 1.0;
    if (phase < 0.72) return -0.32;
    if (phase < 0.76) return 0.22;
    if (phase < 0.82) return 0;
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final midY = size.height * 0.52;
    final amplitude = size.height * (_active ? 0.42 : 0.28);
    final beatSpacing = _active ? size.width * 0.34 : size.width * 0.42;
    final scroll = waveProgress * beatSpacing;
    final strokeWidth = _active ? 1.6 : 1.1;
    final lineAlpha = _active ? 0.95 : 0.58;

    final baselinePaint = Paint()
      ..color = AppColors.trustHigh.withValues(alpha: _active ? 0.1 : 0.06)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      baselinePaint,
    );

    final path = Path();
    var started = false;

    for (var x = 0.0; x <= size.width; x += 1) {
      final worldX = x + scroll;
      final beatIndex = worldX / beatSpacing;
      final phase = beatIndex - beatIndex.floor();
      final y = midY - _beatSample(phase) * amplitude;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    if (_active) {
      final glowPaint = Paint()
        ..color = AppColors.trustHigh.withValues(alpha: 0.22)
        ..strokeWidth = strokeWidth + 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter =  MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawPath(path, glowPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.trustHigh.withValues(alpha: lineAlpha)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Ponteiro de leitura — reforça o efeito “monitor ao vivo”.
    final sweepX = size.width * (0.25 + (math.sin(sweepProgress * math.pi * 2) + 1) * 0.25);
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppColors.trustHigh.withValues(alpha: _active ? 0.28 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(sweepX - 18, 0, 36, size.height));
    canvas.drawRect(
      Rect.fromLTWH(sweepX - 18, 0, 36, size.height),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPulsePainter oldDelegate) =>
      oldDelegate.waveProgress != waveProgress ||
      oldDelegate.sweepProgress != sweepProgress ||
      oldDelegate.intensity != intensity;
}
