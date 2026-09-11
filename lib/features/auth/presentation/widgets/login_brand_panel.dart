import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_surface_card.dart';

/// Painel de marca do login: produto à esquerda (desktop) ou acima do card (mobile).
class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({
    super.key,
    this.logoSize = 152,
    this.centered = false,
    this.showHighlights = true,
    this.fillHeight = false,
    this.embedded = false,
  });

  final double logoSize;

  /// Mobile: textos centralizados.
  final bool centered;

  /// Em telas baixas o mobile omite os bullets para caber o formulário.
  final bool showHighlights;

  /// Desktop: preenche altura sincronizada com o formulário.
  final bool fillHeight;

  /// Dentro do card unificado (sem chrome próprio).
  final bool embedded;

  static const _highlightIcons = <IconData>[
    Icons.lock_outline_rounded,
    Icons.location_on_outlined,
    Icons.smartphone_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.center,
          child: GuardianLogo(size: logoSize, breathe: true),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.center,
          child: Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: (centered
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Text(
            AppConstants.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        if (showHighlights) ...[
          SizedBox(height: centered ? 16 : 18),
          for (var i = 0; i < AppConstants.loginHighlights.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _HighlightRow(
              icon: _highlightIcons[i],
              label: AppConstants.loginHighlights[i],
              centered: centered,
            ),
          ],
        ],
      ],
    );

    // Em desktop a altura é sincronizada com o form; se apertar, rola sem
    // overflow amarelo (mantém o escudo e a respiração).
    final child = fillHeight
        ? LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: body,
                ),
              );
            },
          )
        : body;
    if (embedded) return child;
    return AuthSurfaceCard(child: child);
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
