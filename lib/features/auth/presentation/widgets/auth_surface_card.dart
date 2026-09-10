import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Card de superfície do login (borda em gradiente + sombra suave).
class AuthSurfaceCard extends StatelessWidget {
  const AuthSurfaceCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final narrow = MediaQuery.sizeOf(context).width < 420;
    final cardPad = padding ?? EdgeInsets.all(narrow ? 20.0 : 28.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.trustHigh.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.trustHigh.withValues(alpha: 0.28),
              AppColors.divider.withValues(alpha: 0.9),
              AppColors.trustHigh.withValues(alpha: 0.12),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(1.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: double.infinity,
            padding: cardPad,
            color: AppColors.card.withValues(alpha: 0.92),
            child: child,
          ),
        ),
      ),
    );
  }
}
