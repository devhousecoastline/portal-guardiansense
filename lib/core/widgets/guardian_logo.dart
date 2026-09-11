import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Proporção / resolução nativa de [shield_transparent.png] (igual ao app).
const _shieldAspectRatio = 630 / 834;
const _nativeWidth = 630;
const _nativeHeight = 834;

/// Respiração lenta: escala suave + fade igual à splash do app (0.75→1.0).
const _breatheMinScale = 0.97;
const _breatheMaxScale = 1.03;
const _breatheDuration = Duration(milliseconds: 3200);

class GuardianLogo extends StatelessWidget {
  const GuardianLogo({
    super.key,
    this.size = 64,
    this.breathe = false,
  });

  /// Altura lógica do escudo (largura segue a proporção do PNG).
  final double size;

  /// Respiração lenta no login / marca. Desligado por padrão.
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/shield_transparent.png',
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: kIsWeb ? FilterQuality.medium : FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
      cacheWidth: _nativeWidth,
      cacheHeight: _nativeHeight,
    );

    final logoW = size * _shieldAspectRatio;
    final logoH = size;

    if (!breathe) {
      return SizedBox(width: logoW, height: logoH, child: image);
    }

    return _BreathingLogo(
      logoWidth: logoW,
      logoHeight: logoH,
      child: image,
    );
  }
}

class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo({
    required this.logoWidth,
    required this.logoHeight,
    required this.child,
  });

  final double logoWidth;
  final double logoHeight;
  final Widget child;

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _breatheDuration,
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: _breatheMinScale,
    end: _breatheMaxScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.75,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reserva o pico da escala: textos abaixo não se movem.
    final maxW = widget.logoWidth * _breatheMaxScale;
    final maxH = widget.logoHeight * _breatheMaxScale;

    return SizedBox(
      width: maxW,
      height: maxH,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: SizedBox(
              width: widget.logoWidth,
              height: widget.logoHeight,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

const loginFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
);
