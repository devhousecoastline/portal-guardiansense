import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/events/domain/event_display.dart';
import 'package:guardian_portal/features/events/domain/event_timeline_entry.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_tile.dart';
import 'package:intl/intl.dart';

Future<void> showEventSessionSheet(
  BuildContext context,
  EventTimelineEntry entry,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, controller) {
        final time = DateFormat('HH:mm:ss').format(entry.summary.occurredAt);
        final status = EventDisplay.statusLabel(entry.summary);

        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Auditoria da sessão',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$time · $status',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const Divider(height: 28),
            Text(
              '${entry.sessionEvents.length} registro(s) sincronizado(s) neste intervalo',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 12),
            for (final event in entry.sessionEvents) ...[
              _AuditRow(event: event),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    ),
  );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.event});

  final SecurityEvent event;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(event.occurredAt);
    final status = EventDisplay.statusLabel(event);
    final title = EventDisplay.title(event);
    final subtitle = EventDisplay.subtitle(event);
    final color = EventTile.severityColor(event.severity);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
