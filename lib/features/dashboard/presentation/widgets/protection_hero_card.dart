import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

class ProtectionHeroCard extends StatelessWidget {
  const ProtectionHeroCard({
    super.key,
    required this.status,
    required this.tone,
  });

  final DeviceStatus status;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      StatusTone.protected => AppColors.trustHigh,
      StatusTone.warning => AppColors.trustMedium,
      StatusTone.critical => AppColors.riskCritical,
      StatusTone.offline => AppColors.textMuted,
      StatusTone.neutral => AppColors.primary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          StatusBadge(label: status.protectionLabel.toUpperCase(), tone: tone),
          const SizedBox(height: 20),
          Text(
            status.modelLabel,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            '${status.protectionIndex}%',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
          ),
          const SizedBox(height: 4),
          Text('Proteção', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStat(
                label: 'Runtime',
                value: status.runtimeActive == true ? 'Ativo' : '—',
                color: accent,
              ),
              const SizedBox(width: 32),
              _MiniStat(
                label: 'Escudo',
                value: status.oysterClosed == true ? 'Ativo' : '—',
                color: accent,
              ),
              const SizedBox(width: 32),
              _MiniStat(
                label: 'Sync',
                value: formatRelativeTime(status.lastSeen),
                color: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
