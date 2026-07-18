import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/events/domain/events_deduplicator.dart';
import 'package:guardian_portal/features/events/domain/events_timeline_builder.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

SecurityEvent _event({
  required String id,
  required String title,
  required String summary,
  required DateTime occurredAt,
  SecurityEventSeverity severity = SecurityEventSeverity.warning,
  int? sessionId,
}) {
  return SecurityEvent(
    id: id,
    occurredAt: occurredAt,
    title: title,
    summary: summary,
    severity: severity,
    sessionId: sessionId,
  );
}

void main() {
  final base = DateTime(2026, 7, 7, 18, 0);

  test('remove duplicatas exatas em poucos segundos', () {
    final events = [
      _event(
        id: '1',
        title: 'Padrão de risco detectado',
        summary: 'pocketExtraction',
        occurredAt: base,
      ),
      _event(
        id: '2',
        title: 'Padrão de risco detectado',
        summary: 'pocketExtraction',
        occurredAt: base.add(const Duration(seconds: 2)),
      ),
    ];

    final normalized = EventsDeduplicator.removeExactDuplicates(events);

    expect(normalized, hasLength(1));
  });

  test('colapsa padrões repetidos na janela de 90s', () {
    final events = [
      _event(
        id: '1',
        title: 'Padrão de risco detectado',
        summary: 'pocketExtraction',
        occurredAt: base,
      ),
      _event(
        id: '2',
        title: 'Padrão de risco detectado',
        summary: 'pocketExtraction',
        occurredAt: base.add(const Duration(seconds: 30)),
      ),
    ];

    final collapsed = EventsDeduplicator.collapseSessionLogs(events);

    expect(collapsed, hasLength(1));
    expect(collapsed.first.id, '2');
  });

  test('monta um card por dia com o último evento', () {
    final events = [
      _event(
        id: '1',
        title: 'Risco elevado',
        summary: 'risco attention → elevated',
        occurredAt: DateTime(2026, 7, 7, 19, 17, 21),
        sessionId: 10,
      ),
      _event(
        id: '2',
        title: 'Risco elevado',
        summary: 'risco attention → elevated',
        occurredAt: DateTime(2026, 7, 7, 19, 23, 54),
        sessionId: 11,
      ),
      _event(
        id: '3',
        title: 'Ostra reaberta',
        summary: 'ok',
        occurredAt: DateTime(2026, 7, 7, 19, 34, 40),
        severity: SecurityEventSeverity.info,
        sessionId: 12,
      ),
      _event(
        id: '4',
        title: 'Risco crítico confirmado',
        summary: 'critical',
        occurredAt: DateTime(2026, 7, 6, 10, 0),
        severity: SecurityEventSeverity.critical,
        sessionId: 13,
      ),
    ];

    final timeline = EventsTimelineBuilder.build(events);

    expect(timeline, hasLength(2));
    expect(timeline.first.summary.id, '3');
    expect(timeline.first.dayEvents, hasLength(3));
    expect(timeline.last.summary.id, '4');
    expect(timeline.last.dayEvents, hasLength(1));
  });

  test('agrupa todos os registros do mesmo dia no detalhe', () {
    final events = [
      _event(
        id: '1',
        title: 'Padrão de risco detectado',
        summary: 'pocketExtraction',
        occurredAt: DateTime(2026, 7, 7, 14, 51),
        sessionId: 5,
      ),
      _event(
        id: '2',
        title: 'Risco elevado',
        summary: 'pocketExtraction',
        occurredAt: DateTime(2026, 7, 7, 14, 51, 10),
        sessionId: 5,
      ),
      _event(
        id: '3',
        title: 'Risco crítico confirmado',
        summary: 'critical confirmado',
        occurredAt: DateTime(2026, 7, 7, 14, 51, 20),
        severity: SecurityEventSeverity.critical,
        sessionId: 5,
      ),
    ];

    final timeline = EventsTimelineBuilder.build(events);

    expect(timeline, hasLength(1));
    expect(timeline.first.dayEvents, hasLength(3));
    expect(timeline.first.summary.id, '3');
  });
}
