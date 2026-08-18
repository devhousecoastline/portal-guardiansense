import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_play_store_button.dart';

/// Painel de marca do login: produto à esquerda (desktop) ou acima do card (mobile).
class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({
    super.key,
    this.logoSize = 220,
    this.centered = false,
    this.showHighlights = true,
  });

  final double logoSize;

  /// Mobile: textos centralizados e CTA em largura total.
  final bool centered;

  /// Em telas baixas o mobile omite os bullets para caber o formulário.
  final bool showHighlights;

  static const _highlightIcons = <IconData>[
    Icons.lock_outline_rounded,
    Icons.location_on_outlined,
    Icons.smartphone_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.left;

    return Align(
      alignment: centered ? Alignment.topCenter : Alignment.topLeft,
      child: SizedBox(
        width: centered ? null : 360,
        child: Column(
          crossAxisAlignment:
              centered ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          mainAxisSize:
              centered ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: Transform.translate(
                offset: centered ? Offset.zero : const Offset(-4, -8),
                child: GuardianLogo(size: logoSize, breathe: true),
              ),
            ),
            Transform.translate(
              offset: Offset(0, centered ? -6 : -18),
              child: Text(
                AppConstants.appName,
                textAlign: align,
                style: (centered
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            Text(
              AppConstants.tagline,
              textAlign: align,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (showHighlights) ...[
              SizedBox(height: centered ? 16 : 20),
              for (var i = 0; i < AppConstants.loginHighlights.length; i++) ...[
                if (i > 0) SizedBox(height: centered ? 8 : 10),
                _HighlightRow(
                  icon: _highlightIcons[i],
                  label: AppConstants.loginHighlights[i],
                  centered: centered,
                ),
              ],
            ],
            if (centered)
              const SizedBox(height: 16)
            else
              const Spacer(),
            Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: LoginPlayStoreButton(fullWidth: centered),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.label,
    required this.centered,
  });

  final IconData icon;
  final String label;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.88),
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.trustHigh),
        const SizedBox(width: 10),
        Expanded(child: text),
      ],
    );
  }
}
