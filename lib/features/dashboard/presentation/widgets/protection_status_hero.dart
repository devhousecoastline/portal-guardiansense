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
    this.stretchVertically = false,
  });

  final DeviceStatus status;
  final StatusTone tone;
  final bool stretchVertically;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(tone);
    final headline = ProtectionSnapshot.headline(status);
    final offline = !status.isOnline;

    return SizedBox(
      width: double.infinity,
      height: stretchVertically ? double.infinity : null,
      child: Container(
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
          if (offline) ...[
            const SizedBox(height: 12),
            _OfflineBanner(),
          ],
          const SizedBox(height: 16),
          Text(
            status.modelLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
          ),
          if (stretchVertically) const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                offline ? '—' : '${status.protectionIndex}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      height: 1,
                    ),
              ),
              if (!offline)
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Índice de Proteção',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (offline && status.hasSetupChecklist) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Último: ${status.storedProtectionIndex}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
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
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aparelho offline no momento',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
