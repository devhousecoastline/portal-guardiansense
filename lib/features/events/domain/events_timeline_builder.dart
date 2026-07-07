import 'package:guardian_portal/features/events/domain/event_timeline_entry.dart';
import 'package:guardian_portal/features/events/domain/events_deduplicator.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

/// Monta a linha do tempo do portal como no app: cards colapsados por sessão.
abstract final class EventsTimelineBuilder {
  static const sessionGap = Duration(minutes: 8);
  static const sessionLimit = 40;

  static List<EventTimelineEntry> build(List<SecurityEvent> raw) {
    if (raw.isEmpty) return const [];

    final deduped = EventsDeduplicator.removeExactDuplicates(raw);
    final sessions = _splitSessions(deduped);
    final entries = <EventTimelineEntry>[];

    for (final sessionEvents in sessions) {
      final chronological = [...sessionEvents]
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      final collapsed = EventsDeduplicator.collapseSessionLogs(chronological);
      final audit = [...sessionEvents]
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      for (final summary in collapsed) {
        entries.add(
          EventTimelineEntry(
            summary: summary,
            sessionEvents: audit,
          ),
        );
      }
    }

    entries.sort((a, b) => b.summary.occurredAt.compareTo(a.summary.occurredAt));
    return entries.take(sessionLimit).toList(growable: false);
  }

  static List<List<SecurityEvent>> _splitSessions(List<SecurityEvent> events) {
    final withSessionId = events.where((e) => e.sessionId != null).toList();
    final legacy = events.where((e) => e.sessionId == null).toList();

    final sessions = <List<SecurityEvent>>[];

    if (withSessionId.isNotEmpty) {
      final bySession = <int, List<SecurityEvent>>{};
      for (final event in withSessionId) {
        bySession.putIfAbsent(event.sessionId!, () => []).add(event);
      }
      sessions.addAll(bySession.values);
    }

    if (legacy.isNotEmpty) {
      sessions.addAll(_splitPseudoSessions(legacy));
    }

    return sessions;
  }

  static List<List<SecurityEvent>> _splitPseudoSessions(
    List<SecurityEvent> events,
  ) {
    final sorted = [...events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final sessions = <List<SecurityEvent>>[];
    var current = <SecurityEvent>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final event = sorted[i];
      final gap = event.occurredAt.difference(current.last.occurredAt);
      if (gap > sessionGap) {
        sessions.add(current);
        current = [event];
      } else {
        current.add(event);
      }
    }
    sessions.add(current);
    return sessions;
  }
}
