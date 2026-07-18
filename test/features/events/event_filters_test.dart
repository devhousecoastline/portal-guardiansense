import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/events/domain/event_filters.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

SecurityEvent _event({
  required String title,
  required String summary,
  required SecurityEventSeverity severity,
  required DateTime occurredAt,
}) {
  return SecurityEvent(
    id: title,
    occurredAt: occurredAt,
    title: title,
    summary: summary,
    severity: severity,
  );
}

void main() {
  final now = DateTime(2026, 7, 7, 18, 0);

  test('estado inicial filtra eventos de hoje', () {
    final events = [
      _event(
        title: 'Hoje',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: now,
      ),
      _event(
        title: 'Ontem',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    final filtered = EventFilters.apply(events, EventFilterState.initial, now: now);

    expect(filtered, hasLength(1));
    expect(filtered.first.title, 'Hoje');
    expect(EventFilterState.initial.hasActiveFilters, isFalse);
  });

  test('filtra por severidade e período', () {
    final events = [
      _event(
        title: 'Risco crítico confirmado',
        summary: 'spike',
        severity: SecurityEventSeverity.critical,
        occurredAt: now.subtract(const Duration(hours: 2)),
      ),
      _event(
        title: 'Ostra reaberta',
        summary: 'ok',
        severity: SecurityEventSeverity.info,
        occurredAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    final filtered = EventFilters.apply(
      events,
      const EventFilterState(
        severity: SecurityEventSeverity.critical,
        period: EventPeriod.today,
      ),
      now: now,
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.title, 'Risco crítico confirmado');
  });

  test('filtra por categoria ostra', () {
    final events = [
      _event(
        title: 'Ostra fechada',
        summary: 'ostra fechada',
        severity: SecurityEventSeverity.warning,
        occurredAt: now,
      ),
      _event(
        title: 'Risco elevado',
        summary: 'spike',
        severity: SecurityEventSeverity.warning,
        occurredAt: now,
      ),
    ];

    final filtered = EventFilters.apply(
      events,
      const EventFilterState(category: EventCategoryFilter.oyster),
      now: now,
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.category, EventCategory.oyster);
  });

  test('filtra por intervalo personalizado no calendário', () {
    final events = [
      _event(
        title: 'A',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: DateTime(2026, 7, 1, 12),
      ),
      _event(
        title: 'B',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: DateTime(2026, 7, 5, 12),
      ),
      _event(
        title: 'C',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: DateTime(2026, 7, 10, 12),
      ),
    ];

    final filtered = EventFilters.apply(
      events,
      EventFilterState(
        customRange: DateTimeRange(
          start: DateTime(2026, 7, 3),
          end: DateTime(2026, 7, 8),
        ),
      ),
      now: now,
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.title, 'B');
  });

  test('agrupa eventos por dia', () {
    final events = [
      _event(
        title: 'A',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: now,
      ),
      _event(
        title: 'B',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: now.subtract(const Duration(days: 1)),
      ),
      _event(
        title: 'C',
        summary: '',
        severity: SecurityEventSeverity.info,
        occurredAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    final groups = EventFilters.groupByDay(events, now: now);

    expect(groups.keys, ['Hoje · 07/07/2026', 'Ontem · 06/07/2026', '04/07/2026']);
    expect(groups['Hoje · 07/07/2026'], hasLength(1));
    expect(
      EventFilters.dayLabelFor(now.subtract(const Duration(days: 3)), now: now),
      '04/07/2026',
    );
  });
}
