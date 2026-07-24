import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_footer.dart';

/// Fundo e estrutura compartilhados das telas de autenticação.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.body,
  });

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.15, -0.08),
                radius: 1.05,
                colors: [
                  AppColors.loginBackgroundCenter,
                  AppColors.loginBackgroundMid,
                  AppColors.loginBackgroundEdge,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          if (isDark) ...[
            // Glow esquerda (escudo).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: wide
                      ? const Alignment(-0.35, -0.05)
                      : const Alignment(0, -0.18),
                  radius: wide ? 0.65 : 0.72,
                  colors: [
                    AppColors.trustHigh.withValues(alpha: wide ? 0.09 : 0.08),
                    AppColors.trustHigh.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            // Mesmo fundo, espelhado na direita.
            if (wide)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.42, -0.05),
                    radius: 0.92,
                    colors: [
                      AppColors.trustHigh.withValues(alpha: 0.09),
                      AppColors.trustHigh.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
          ],
          SafeArea(
            child: Column(
              children: [
                Expanded(child: body),
                const AuthFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
