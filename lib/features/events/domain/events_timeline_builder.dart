import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/event_timeline_entry.dart';
import 'package:guardian_portal/features/events/domain/events_deduplicator.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

/// Monta a linha do tempo do portal: **um card por dia**.
///
/// O card exibe o último evento do dia; o detalhe lista todos os registros
/// daquela data.
abstract final class EventsTimelineBuilder {
  static const dayLimit = 120;

  static List<EventTimelineEntry> build(List<SecurityEvent> raw) {
    if (raw.isEmpty) return const [];

    final deduped = EventsDeduplicator.removeExactDuplicates(raw);
    final byDay = <DateTime, List<SecurityEvent>>{};

    for (final event in deduped) {
      final day = EventFilters.calendarDay(event.occurredAt);
      byDay.putIfAbsent(day, () => []).add(event);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final entries = <EventTimelineEntry>[];

    for (final day in days.take(dayLimit)) {
      final events = [...byDay[day]!]
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      entries.add(
        EventTimelineEntry(
          summary: events.first,
          dayEvents: List.unmodifiable(events),
        ),
      );
    }

    return entries;
  }
}
