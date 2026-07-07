import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/event_timeline_entry.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_session_sheet.dart';
import 'package:guardian_portal/features/events/presentation/widgets/event_tile.dart';

class EventsStatsBar extends StatelessWidget {
  const EventsStatsBar({super.key, required this.stats});

  final EventStats stats;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (stats.visible == stats.total)
        '${stats.total} ${stats.total == 1 ? 'evento' : 'eventos'}'
      else
        'Mostrando ${stats.visible} de ${stats.total}',
      if (stats.critical > 0) '${stats.critical} crítico${stats.critical == 1 ? '' : 's'}',
      if (stats.warning > 0) '${stats.warning} atenção',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventsTimeline extends StatelessWidget {
  const EventsTimeline({super.key, required this.entries});

  final List<EventTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<EventTimelineEntry>>{};
    for (final entry in entries) {
      final dayKey = EventFilters.groupByDay([entry.summary]).keys.first;
      groups.putIfAbsent(dayKey, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final dayKey in groups.keys) ...[
          _DayHeader(label: dayKey),
          const SizedBox(height: 8),
          for (final entry in groups[dayKey]!) ...[
            EventTile(
              event: entry.summary,
              detailCount: entry.sessionEvents.length,
              onTap: () => showEventSessionSheet(context, entry),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
