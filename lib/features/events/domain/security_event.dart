import 'package:cloud_firestore/cloud_firestore.dart';

enum SecurityEventSeverity { info, warning, critical }

class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.occurredAt,
    required this.title,
    required this.summary,
    required this.severity,
  });

  final String id;
  final DateTime occurredAt;
  final String title;
  final String summary;
  final SecurityEventSeverity severity;

  factory SecurityEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['occurredAt'];
    final occurredAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return SecurityEvent(
      id: doc.id,
      occurredAt: occurredAt,
      title: data['title'] as String? ?? 'Evento',
      summary: data['summary'] as String? ?? '',
      severity: _severity(data['severity'] as String?),
    );
  }

  static SecurityEventSeverity _severity(String? raw) => switch (raw) {
        'critical' => SecurityEventSeverity.critical,
        'warning' => SecurityEventSeverity.warning,
        _ => SecurityEventSeverity.info,
      };
}
