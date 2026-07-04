import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.device});

  final GuardianDevice device;

  @override
  Widget build(BuildContext context) {
    final status = device.status;
    final tone = switch (status.level) {
      ProtectionLevel.protected => StatusTone.protected,
      ProtectionLevel.partial => StatusTone.warning,
      ProtectionLevel.alert => StatusTone.critical,
      ProtectionLevel.offline => StatusTone.offline,
      ProtectionLevel.unknown => StatusTone.neutral,
    };

    return SectionCard(
      child: Row(
        children: [
          Icon(
            status.platform == 'ios'
                ? Icons.phone_iphone_outlined
                : Icons.smartphone_outlined,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.modelLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Sync ${formatRelativeTime(status.lastSeen)} · v${status.appVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: status.isOnline ? status.protectionLabel : 'Offline',
            tone: tone,
          ),
        ],
      ),
    );
  }
}
