import 'package:flutter/material.dart';

/// Proporção de [shield_transparent.png] (630×834).
const _shieldAspectRatio = 630 / 834;

class GuardianLogo extends StatelessWidget {
  const GuardianLogo({
    super.key,
    this.size = 64,
    this.breathe = false,
  });

  final double size;

  /// Respiração suave (login / hero). Desligado por padrão.
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final renderH = size;
    final renderW = size * _shieldAspectRatio;

    final logo = RepaintBoundary(
      child: SizedBox(
        width: renderW,
        height: renderH,
        child: Image.asset(
          'assets/images/shield_transparent.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          cacheWidth: (renderW * dpr).round().clamp(1, 4096),
          cacheHeight: (renderH * dpr).round().clamp(1, 4096),
          gaplessPlayback: true,
        ),
      ),
    );

    if (!breathe) return logo;
    return _BreathingLogo(child: logo);
  }
}

class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo({required this.child});

  final Widget child;

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

const loginFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
);
