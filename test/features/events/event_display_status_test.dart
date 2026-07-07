import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/events/domain/event_display.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

void main() {
  test('statusLabel para risco elevado', () {
    final event = SecurityEvent(
      id: '1',
      occurredAt: DateTime.now(),
      title: 'Risco elevado',
      summary: 'risco attention → elevated',
      severity: SecurityEventSeverity.warning,
    );

    expect(EventDisplay.statusLabel(event), 'RISCO ELEVADO');
  });
}
