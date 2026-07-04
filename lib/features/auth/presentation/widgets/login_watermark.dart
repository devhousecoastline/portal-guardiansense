import 'package:flutter/material.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';

/// Escudo gigante no fundo — ~3% de opacidade, quase imperceptível.
/// Posicionado abaixo do centro para não sobrepor a logo do topo.
class LoginWatermark extends StatelessWidget {
  const LoginWatermark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.52),
        child: Opacity(
          opacity: 0.03,
          child: GuardianLogo(size: size),
        ),
      ),
    );
  }
}
