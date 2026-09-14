import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/dashboard/domain/device_situation.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

/// Badge somente leitura — mesmo idioma do app (`Casa · Ambiente confiável`).
///
/// Linha única no notebook/desktop. Em mobile estreito o hint pode quebrar
/// para a linha de baixo sem apertar o card.
/// Não altera proteção, ostra nem contenção.
class SituationContextBadge extends StatelessWidget {
  const SituationContextBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final DeviceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final situation = status.situation;
    if (situation == null) return const SizedBox.shrink();

    final accent = _accent(situation);
    final isMobile =
        MediaQuery.sizeOf(context).width < AppLayout.dashboardRowBreakpoint;
    final fontSize = compact ? 12.0 : 13.0;

    return Align(
      child: ConstrainedBox(
        // No notebook o pill fica solto e legível; no mobile limita o stretch.
        constraints: BoxConstraints(maxWidth: isMobile ? 280 : 360),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: situation.labelPt,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' · ',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: fontSize,
                        ),
                      ),
                      TextSpan(
                        text: situation.hintPt,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                  // Mobile: até 2 linhas se faltar largura; notebook fica 1 linha.
                  maxLines: isMobile ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accent(DeviceSituation s) => switch (s) {
        DeviceSituation.home || DeviceSituation.trusted => AppColors.trustHigh,
        DeviceSituation.street => AppColors.riskElevated,
        DeviceSituation.transit => AppColors.trustMedium,
        DeviceSituation.unknown => AppColors.textMuted,
      };
}
