import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

/// Teaser do plano premium — preenche o espaço do drawer (como no app).
class DrawerPremiumTeaser extends StatelessWidget {
  const DrawerPremiumTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Guardian Premium — em breve.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.star_outline_rounded,
                  color: AppColors.trustMedium.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guardian Premium',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Em breve',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
