import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/domain/device_switches.dart';
import 'package:intl/intl.dart';

/// Resumo da cota anual de trocas (`users/{uid}.deviceSwitches`).
class DeviceSwitchesCard extends StatelessWidget {
  const DeviceSwitchesCard({super.key, required this.switches});

  final DeviceSwitches switches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = switches.remaining;
    final exhausted = !switches.canSwitch;
    final accent = exhausted ? AppColors.trustMedium : AppColors.primary;
    final periodLabel =
        DateFormat('dd/MM/yyyy').format(switches.periodEnd.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              exhausted ? Icons.swap_horiz_outlined : Icons.phonelink_setup,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exhausted
                        ? 'Trocas do período esgotadas'
                        : 'Trocas de aparelho',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${switches.used} de ${switches.allowance} usadas'
                    '${remaining == 0 ? '' : ' · $remaining restante'
                        '${remaining == 1 ? '' : 's'}'}'
                    ' · válido até $periodLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (exhausted) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Para vincular outro aparelho, compre uma troca extra '
                      'no app Guardian Sense.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
