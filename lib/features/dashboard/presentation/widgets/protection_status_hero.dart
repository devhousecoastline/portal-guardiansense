import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionStatusHero extends StatelessWidget {
  const ProtectionStatusHero({
    super.key,
    required this.status,
    required this.tone,
    this.stretchVertically = false,
    this.fillHeight = false,
    this.compact = false,
  });

  final DeviceStatus status;
  final StatusTone tone;
  final bool stretchVertically;
  final bool fillHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(tone);
    final headline = ProtectionSnapshot.headline(status);
    final offline = !status.isOnline;
    final cardPadding = compact ? 12.0 : 24.0;
    final indexSize = compact ? 32.0 : 52.0;
    final expands = stretchVertically || fillHeight;

    return SizedBox(
      width: double.infinity,
      height: expands ? double.infinity : null,
      child: Container(
      width: double.infinity,
      height: expands ? double.infinity : null,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: status.protectionLabel.toUpperCase(), tone: tone),
          if (offline) ...[
            SizedBox(height: compact ? 6 : 12),
            _OfflineBanner(compact: compact),
          ],
          SizedBox(height: compact ? 6 : 16),
          if (fillHeight) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    status.modelLabel,
                    style: DashboardTypography.deviceName(
                      context,
                      compact: compact,
                    ),
                    maxLines: compact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _indexColumn(
                  context,
                  accent: accent,
                  offline: offline,
                  indexSize: indexSize,
                ),
              ],
            ),
            const Spacer(),
          ] else ...[
            Text(
              status.modelLabel,
              style: DashboardTypography.deviceName(context, compact: compact),
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
            ),
            if (!compact) ...[
               SizedBox(height: 8),
              Text(
                headline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
              ),
            ],
            if (stretchVertically) const Spacer(),
            _indexRow(
              context,
              accent: accent,
              offline: offline,
              indexSize: indexSize,
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _indexColumn(
    BuildContext context, {
    required Color accent,
    required bool offline,
    required double indexSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              offline ? '—' : '${status.protectionIndex}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: indexSize,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1,
                  ),
            ),
            if (!offline)
              Padding(
                padding: EdgeInsets.only(bottom: compact ? 3 : 6, left: 2),
                child: Text(
                  '%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 16 : null,
                      ),
                ),
              ),
          ],
        ),
        Text(
          'Índice de Proteção',
          style: DashboardTypography.mutedLabel(context),
        ),
        if (offline && status.hasSetupChecklist)
          Text(
            'Último: ${status.storedProtectionIndex}%',
            style: DashboardTypography.mutedLabel(context),
          ),
      ],
    );
  }

  Widget _indexRow(
    BuildContext context, {
    required Color accent,
    required bool offline,
    required double indexSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          offline ? '—' : '${status.protectionIndex}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: indexSize,
                fontWeight: FontWeight.w700,
                color: accent,
                height: 1,
              ),
        ),
        if (!offline)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 3 : 6, left: 2),
            child: Text(
              '%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 16 : null,
                  ),
            ),
          ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Índice de Proteção',
              style: compact
                  ? DashboardTypography.mutedLabel(context)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
            if (offline && status.hasSetupChecklist) ...[
              const SizedBox(height: 4),
              Text(
                'Último: ${status.storedProtectionIndex}%',
                style: DashboardTypography.mutedLabel(context),
              ),
            ],
          ],
        ),
      ],
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
  const _OfflineBanner({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
           Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aparelho offline no momento',
              style: DashboardTypography.mutedLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}
