import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:intl/intl.dart';

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event});

  final SecurityEvent event;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.severity) {
      SecurityEventSeverity.critical => AppColors.riskCritical,
      SecurityEventSeverity.warning => AppColors.riskElevated,
      SecurityEventSeverity.info => AppColors.textMuted,
    };

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('HH:mm').format(event.occurredAt),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(width: 16),
          Container(width: 2, height: 40, color: color.withValues(alpha: 0.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                if (event.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(event.summary, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
