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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(
              label: status.protectionLabel.toUpperCase(),
              tone: tone,
            ),
            if (offline) ...[
              SizedBox(height: compact ? 6 : 12),
              _OfflineBanner(compact: compact),
            ],
            if (fillHeight) ...[
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: compact ? 6 : 8),
                    child: Text(
                      headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            fontSize: compact ? 13.5 : 15,
                          ),
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Divider(
                height: compact ? 12 : 14,
                thickness: 1,
                color: AppColors.divider.withValues(alpha: 0.9),
              ),
              SizedBox(height: compact ? 6 : 8),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _IndexBlock(
                    status: status,
                    accent: accent,
                    offline: offline,
                    indexSize: indexSize,
                    compact: compact,
                    alignEnd: true,
                  ),
                ],
              ),
            ] else ...[
              SizedBox(height: compact ? 6 : 16),
              Text(
                status.modelLabel,
                style: DashboardTypography.deviceName(context, compact: compact),
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                ),
              ],
              if (stretchVertically) const Spacer(),
              if (!stretchVertically) SizedBox(height: compact ? 10 : 16),
              if (stretchVertically)
                Divider(
                  height: compact ? 16 : 20,
                  thickness: 1,
                  color: AppColors.divider.withValues(alpha: 0.9),
                ),
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

  Widget _indexRow(
    BuildContext context, {
    required Color accent,
    required bool offline,
    required double indexSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _IndexBlock(
          status: status,
          accent: accent,
          offline: offline,
          indexSize: indexSize,
          compact: compact,
          alignEnd: false,
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

class _IndexBlock extends StatelessWidget {
  const _IndexBlock({
    required this.status,
    required this.accent,
    required this.offline,
    required this.indexSize,
    required this.compact,
    required this.alignEnd,
  });

  final DeviceStatus status;
  final Color accent;
  final bool offline;
  final double indexSize;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
        if (alignEnd) ...[
          const SizedBox(height: 2),
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
      ],
    );
  }
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
