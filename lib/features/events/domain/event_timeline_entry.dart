import 'package:guardian_portal/features/events/domain/security_event.dart';

/// Card da linha do tempo: um por dia civil.
class EventTimelineEntry {
  const EventTimelineEntry({
    required this.summary,
    required this.dayEvents,
  });

  /// Último evento do dia — o que aparece no card.
  final SecurityEvent summary;

  /// Todos os registros daquele dia (toque para abrir).
  final List<SecurityEvent> dayEvents;
}
