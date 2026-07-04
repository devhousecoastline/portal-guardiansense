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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respostas em segundos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'O que importa sobre a proteção do seu aparelho.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => _ChecklistRow(entry: entry),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.entry});

  final ProtectionChecklistEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.signal) {
      ChecklistSignal.ok => AppColors.trustHigh,
      ChecklistSignal.warn => AppColors.trustMedium,
      ChecklistSignal.alert => AppColors.riskCritical,
      ChecklistSignal.muted => AppColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.question,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.answer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
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
