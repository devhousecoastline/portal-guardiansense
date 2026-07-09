import 'package:flutter/material.dart';

/// Proporção de [shield_transparent.png] (630×834).
const _shieldAspectRatio = 630 / 834;

class GuardianLogo extends StatelessWidget {
  const GuardianLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final renderH = size;
    final renderW = size * _shieldAspectRatio;

    return RepaintBoundary(
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
  }
}

const loginFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
);
