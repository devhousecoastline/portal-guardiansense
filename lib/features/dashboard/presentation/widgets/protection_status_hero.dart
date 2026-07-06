import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionStatusHero extends StatelessWidget {
  const ProtectionStatusHero({
    super.key,
    required this.status,
    required this.tone,
  });

  final DeviceStatus status;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(tone);
    final headline = ProtectionSnapshot.headline(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: status.protectionLabel.toUpperCase(), tone: tone),
          const SizedBox(height: 16),
          Text(
            status.modelLabel,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          if (status.hasSetupChecklist) ...[
            Text(
              _setupSummary(status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${status.protectionIndex}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      height: 1,
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text(
                  '%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                'Índice de Proteção',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _accent(StatusTone tone) => switch (tone) {
        StatusTone.protected => AppColors.trustHigh,
        StatusTone.warning => AppColors.trustMedium,
        StatusTone.critical => AppColors.riskCritical,
        StatusTone.offline => AppColors.textMuted,
        StatusTone.neutral => AppColors.primary,
      };

  String _setupSummary(DeviceStatus status) {
    final total = status.protectionSetupItems.length;
    final done = status.configuredSetupItems.length;
    if (done == total) return '$done de $total requisitos configurados no app';
    return '$done de $total requisitos — falta ${total - done}';
  }
}
