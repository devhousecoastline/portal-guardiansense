import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/device_verified_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.device});

  final GuardianDevice device;

  @override
  Widget build(BuildContext context) {
    final status = device.status;
    final released = status.isReleased;
    final color = _toneColor(status);
    final theme = Theme.of(context);
    final statusLine = released
        ? 'Desvinculado'
        : status.isOnline
            ? status.protectionLabel
            : 'Offline';
    final syncLabel = released
        ? _releasedLabel(status.releasedAt)
        : _syncLabel(status.lastSeen);
    final version = status.appVersion.trim().isEmpty
        ? null
        : 'v${status.appVersion}';
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final presenceLabel = released
        ? 'Anterior'
        : status.isOnline
            ? 'Online'
            : 'Offline';

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          status.platform == 'ios'
                              ? Icons.phone_iphone_outlined
                              : Icons.smartphone_outlined,
                          size: 18,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: presenceLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ·  ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  TextSpan(
                                    text: statusLine,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              status.modelLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                syncLabel,
                                if (!released && version != null) version,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.25,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!narrow) ...[
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GuardianHeaderChip(
                              label: statusLine,
                              color: color,
                              icon: _statusIcon(status, released: released),
                            ),
                            if (!released && status.isVerified) ...[
                              const SizedBox(height: 6),
                              const DeviceVerifiedChip(compact: true),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _statusIcon(
    DeviceStatus status, {
    required bool released,
  }) {
    if (released) return Icons.link_off_rounded;
    if (!status.isOnline) return Icons.cloud_off_outlined;
    return switch (status.level) {
      ProtectionLevel.protected => Icons.shield_outlined,
      ProtectionLevel.partial => Icons.shield_moon_outlined,
      ProtectionLevel.alert => Icons.warning_amber_rounded,
      ProtectionLevel.offline => Icons.cloud_off_outlined,
      ProtectionLevel.unknown => Icons.hourglass_empty_rounded,
    };
  }

  static Color _toneColor(DeviceStatus status) {
    if (status.isReleased) return AppColors.textMuted;
    if (!status.isOnline) return AppColors.textMuted;
    return switch (status.level) {
      ProtectionLevel.protected => AppColors.trustHigh,
      ProtectionLevel.partial => AppColors.trustMedium,
      ProtectionLevel.alert => AppColors.riskCritical,
      ProtectionLevel.offline => AppColors.textMuted,
      ProtectionLevel.unknown => AppColors.primary,
    };
  }

  static String _syncLabel(DateTime? lastSeen) {
    final relative = formatRelativeTime(lastSeen);
    if (relative == '—') return 'Sem sincronização';
    if (relative == 'agora') return 'Sincronizado agora';
    return 'Sincronizado $relative';
  }

  static String _releasedLabel(DateTime? releasedAt) {
    final relative = formatRelativeTime(releasedAt);
    if (relative == '—') return 'Desvinculado';
    if (relative == 'agora') return 'Desvinculado agora';
    return 'Desvinculado $relative';
  }
}
