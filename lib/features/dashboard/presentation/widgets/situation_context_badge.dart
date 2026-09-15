import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';
import 'package:guardian_portal/features/dashboard/domain/device_situation.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

/// Chip somente leitura — mesmo idioma do app (`Casa · Ambiente confiável`).
///
/// Vai no cabeçalho ao lado de Online / Verificado. Não altera proteção,
/// ostra nem contenção.
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
    final label = compact
        ? situation.labelPt
        : '${situation.labelPt} · ${situation.hintPt}';

    return GuardianHeaderChip(
      label: label,
      color: accent,
      leading: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
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
