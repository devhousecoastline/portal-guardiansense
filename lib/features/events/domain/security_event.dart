import 'package:cloud_firestore/cloud_firestore.dart';

enum SecurityEventSeverity { info, warning, critical }

enum EventCategory { oyster, risk, protection, blocked, normal, other }

class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.occurredAt,
    required this.title,
    required this.summary,
    required this.severity,
    this.sessionId,
    this.kind,
  });

  final String id;
  final DateTime occurredAt;
  final String title;
  final String summary;
  final SecurityEventSeverity severity;
  final int? sessionId;
  final String? kind;

  bool get isNormalSession =>
      kind == 'session_normal' || title.toLowerCase().contains('uso legítimo');

  EventCategory get category {
    if (isNormalSession) return EventCategory.normal;
    final text = '${title.toLowerCase()} ${summary.toLowerCase()}';
    if (text.contains('ostra')) return EventCategory.oyster;
    if (text.contains('bloqueado')) return EventCategory.blocked;
    if (text.contains('proteção')) return EventCategory.protection;
    if (text.contains('risco') || text.contains('padrão')) {
      return EventCategory.risk;
    }
    return EventCategory.other;
  }

  String get severityLabel => switch (severity) {
        SecurityEventSeverity.critical => 'Crítico',
        SecurityEventSeverity.warning => 'Atenção',
        SecurityEventSeverity.info => 'Info',
      };

  factory SecurityEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['occurredAt'];
    final occurredAt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final sessionId = data['sessionId'];

    return SecurityEvent(
      id: doc.id,
      occurredAt: occurredAt,
      title: data['title'] as String? ?? 'Evento',
      summary: data['summary'] as String? ?? '',
      severity: _severity(data['severity'] as String?),
      sessionId: sessionId is int ? sessionId : (sessionId as num?)?.toInt(),
      kind: data['kind'] as String?,
    );
  }

  static SecurityEventSeverity _severity(String? raw) => switch (raw) {
        'critical' => SecurityEventSeverity.critical,
        'warning' => SecurityEventSeverity.warning,
        _ => SecurityEventSeverity.info,
      };
}
