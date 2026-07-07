import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_footer.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_watermark.dart';

/// Fundo e estrutura compartilhados entre Home e Login.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.appBar,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 0.95,
                colors: [
                  AppColors.loginBackgroundCenter,
                  AppColors.loginBackgroundMid,
                  AppColors.loginBackgroundEdge,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return LoginWatermark(
                size: math.min(constraints.maxWidth * 0.42, 520),
              );
            },
          ),
          Column(
            children: [
              Expanded(child: body),
              const AuthFooter(),
            ],
          ),
        ],
      ),
    );
  }
}
