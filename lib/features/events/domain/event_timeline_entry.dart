import 'package:guardian_portal/features/events/domain/security_event.dart';

/// Card da linha do tempo + eventos brutos da mesma sessão (auditoria).
class EventTimelineEntry {
  const EventTimelineEntry({
    required this.summary,
    required this.sessionEvents,
  });

  /// O que aparece na lista — espelha o card colapsado do app.
  final SecurityEvent summary;

  /// Todos os registros sincronizados naquele intervalo (toque para abrir).
  final List<SecurityEvent> sessionEvents;
}
