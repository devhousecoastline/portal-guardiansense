import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionChecklistCard extends StatelessWidget {
  const ProtectionChecklistCard({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final entries = ProtectionSnapshot.checklist(status);

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respostas em segundos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Status em tempo real do aparelho.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => _ChecklistRow(
              entry: entry,
              compact: entry.answer.length > 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.entry, this.compact = false});

  final ProtectionChecklistEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.signal) {
      ChecklistSignal.ok => AppColors.trustHigh,
      ChecklistSignal.warn => AppColors.trustMedium,
      ChecklistSignal.alert => AppColors.riskCritical,
      ChecklistSignal.muted => AppColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.question,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.answer,
                  style: (compact
                          ? Theme.of(context).textTheme.bodyMedium
                          : Theme.of(context).textTheme.titleSmall)
                      ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
