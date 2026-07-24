import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';

/// Painel de marca do login (desktop): escudo à esquerda do formulário.
class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key, this.logoSize = 220});

  final double logoSize;

  static const _highlightIcons = <IconData>[
    Icons.shield_outlined,
    Icons.bolt_outlined,
    Icons.lock_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-4, -8),
                child: GuardianLogo(size: logoSize, breathe: true),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Text(
                AppConstants.appName,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
              ),
            ),
            Text(
              AppConstants.tagline,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < AppConstants.loginHighlights.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _HighlightRow(
                icon: _highlightIcons[i],
                label: AppConstants.loginHighlights[i],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '* ${AppConstants.loginTrustLine}',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.85),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.trustHigh),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}
