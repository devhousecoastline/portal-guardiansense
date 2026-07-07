import 'package:guardian_portal/features/events/domain/event_display.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

/// Remove duplicatas e colapsa logs — espelha [collapseSessionLogs] do app.
abstract final class EventsDeduplicator {
  static const collapseWindow = Duration(seconds: 90);

  static List<SecurityEvent> collapseSessionLogs(List<SecurityEvent> logs) {
    return collapseRiskElevatedLogs(collapsePatternDetectedLogs(logs));
  }

  /// Mesmo título/resumo em poucos segundos (ex.: Flutter + nativo).
  static List<SecurityEvent> removeExactDuplicates(List<SecurityEvent> raw) {
    if (raw.length <= 1) return raw;

    final sorted = [...raw]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final out = <SecurityEvent>[];

    for (final event in sorted) {
      final isDup = out.any(
        (existing) =>
            existing.title == event.title &&
            existing.summary == event.summary &&
            event.occurredAt.difference(existing.occurredAt).abs() <=
                const Duration(seconds: 5),
      );
      if (!isDup) out.add(event);
    }
    return out;
  }

  static List<SecurityEvent> collapsePatternDetectedLogs(
    List<SecurityEvent> logs,
  ) {
    if (logs.isEmpty) return logs;

    final sorted = [...logs]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final out = <SecurityEvent>[];
    SecurityEvent? pending;

    void flush() {
      if (pending != null) {
        out.add(pending!);
        pending = null;
      }
    }

    for (final event in sorted) {
      if (!_isPatternEvent(event)) {
        flush();
        out.add(event);
        continue;
      }

      final key = _patternKey(event);
      if (pending == null) {
        pending = event;
        continue;
      }

      final pendingKey = _patternKey(pending!);
      final gap = event.occurredAt.difference(pending!.occurredAt);
      if (key == pendingKey && gap <= collapseWindow) {
        pending = event;
      } else {
        flush();
        pending = event;
      }
    }
    flush();
    return out;
  }

  static List<SecurityEvent> collapseRiskElevatedLogs(
    List<SecurityEvent> logs,
  ) {
    if (logs.isEmpty) return logs;

    final sorted = [...logs]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final out = <SecurityEvent>[];
    SecurityEvent? pending;

    void flush() {
      if (pending != null) {
        out.add(pending!);
        pending = null;
      }
    }

    for (final event in sorted) {
      if (!_isRiskElevatedEvent(event)) {
        flush();
        out.add(event);
        continue;
      }

      if (pending == null) {
        pending = event;
        continue;
      }

      final gap = event.occurredAt.difference(pending!.occurredAt);
      if (gap <= collapseWindow) {
        pending = event;
      } else {
        flush();
        pending = event;
      }
    }
    flush();
    return out;
  }

  static bool _isPatternEvent(SecurityEvent event) {
    final title = event.title.toLowerCase();
    return title.contains('padrão');
  }

  static bool _isRiskElevatedEvent(SecurityEvent event) {
    final title = event.title.toLowerCase();
    return title.contains('risco elevado') ||
        title.contains('movimento brusco');
  }

  static String _patternKey(SecurityEvent event) {
    final human = EventDisplay.humanizeSummary(event.summary);
    if (human != null && human.isNotEmpty) return human.toLowerCase();
    return event.summary.toLowerCase();
  }
}
