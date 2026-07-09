import 'package:flutter/material.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:intl/intl.dart';

enum EventPeriod { today, last7Days, last30Days, all }

enum EventCategoryFilter { all, oyster, risk, protection, blocked }

class EventFilterState {
  const EventFilterState({
    this.severity,
    this.period = EventPeriod.today,
    this.category = EventCategoryFilter.all,
    this.customRange,
  });

  final SecurityEventSeverity? severity;
  final EventPeriod period;
  final EventCategoryFilter category;
  final DateTimeRange? customRange;

  static const initial = EventFilterState();

  bool get hasActiveFilters =>
      severity != null ||
      period != EventPeriod.today ||
      category != EventCategoryFilter.all ||
      customRange != null;

  EventFilterState copyWith({
    SecurityEventSeverity? severity,
    bool clearSeverity = false,
    EventPeriod? period,
    EventCategoryFilter? category,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
  }) {
    return EventFilterState(
      severity: clearSeverity ? null : (severity ?? this.severity),
      period: period ?? this.period,
      category: category ?? this.category,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
    );
  }
}

abstract final class EventFilters {
  static List<SecurityEvent> apply(
    List<SecurityEvent> events,
    EventFilterState filters, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return events.where((event) {
      if (filters.severity != null && event.severity != filters.severity) {
        return false;
      }
      if (!_matchesPeriod(
        event.occurredAt,
        filters,
        reference,
      )) {
        return false;
      }
      if (filters.category != EventCategoryFilter.all &&
          event.category != _categoryFromFilter(filters.category)) {
        return false;
      }
      return true;
    }).toList();
  }

  static String formatCustomRange(DateTimeRange range) {
    final fmt = DateFormat('dd/MM/yy');
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    if (start == end) return fmt.format(start);
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  static Map<SecurityEventSeverity, int> severityCounts(
    List<SecurityEvent> events,
  ) {
    return {
      for (final severity in SecurityEventSeverity.values)
        severity: events.where((e) => e.severity == severity).length,
    };
  }

  static Map<EventCategoryFilter, int> categoryCounts(
    List<SecurityEvent> events,
  ) {
    return {
      EventCategoryFilter.all: events.length,
      EventCategoryFilter.oyster: events
          .where((e) => e.category == EventCategory.oyster)
          .length,
      EventCategoryFilter.risk: events
          .where((e) => e.category == EventCategory.risk)
          .length,
      EventCategoryFilter.protection: events
          .where((e) => e.category == EventCategory.protection)
          .length,
      EventCategoryFilter.blocked: events
          .where((e) => e.category == EventCategory.blocked)
          .length,
    };
  }

  static EventStats stats(List<SecurityEvent> all, List<SecurityEvent> filtered) {
    final critical =
        filtered.where((e) => e.severity == SecurityEventSeverity.critical).length;
    final warning =
        filtered.where((e) => e.severity == SecurityEventSeverity.warning).length;
    return EventStats(
      total: all.length,
      visible: filtered.length,
      critical: critical,
      warning: warning,
    );
  }

  static Map<String, List<SecurityEvent>> groupByDay(
    List<SecurityEvent> events, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final groups = <String, List<SecurityEvent>>{};

    for (final event in events) {
      final key = _dayKey(event.occurredAt, reference);
      groups.putIfAbsent(key, () => []).add(event);
    }
    return groups;
  }

  static String dayLabel(String key) => key;

  static String _dayKey(DateTime at, DateTime now) {
    final local = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(local).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    final months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${at.day.toString().padLeft(2, '0')} ${months[at.month - 1]} ${at.year}';
  }

  static bool _matchesPeriod(
    DateTime at,
    EventFilterState filters,
    DateTime now,
  ) {
    if (filters.customRange != null) {
      return _inCustomRange(at, filters.customRange!);
    }

    return switch (filters.period) {
      EventPeriod.all => true,
      EventPeriod.today => _isSameDay(at, now),
      EventPeriod.last7Days => now.difference(at) <= const Duration(days: 7),
      EventPeriod.last30Days => now.difference(at) <= const Duration(days: 30),
    };
  }

  static bool _inCustomRange(DateTime at, DateTimeRange range) {
    final day = DateTime(at.year, at.month, at.day);
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static EventCategory _categoryFromFilter(EventCategoryFilter filter) =>
      switch (filter) {
        EventCategoryFilter.oyster => EventCategory.oyster,
        EventCategoryFilter.risk => EventCategory.risk,
        EventCategoryFilter.protection => EventCategory.protection,
        EventCategoryFilter.blocked => EventCategory.blocked,
        EventCategoryFilter.all => EventCategory.other,
      };
}

class EventStats {
  const EventStats({
    required this.total,
    required this.visible,
    required this.critical,
    required this.warning,
  });

  final int total;
  final int visible;
  final int critical;
  final int warning;
}
