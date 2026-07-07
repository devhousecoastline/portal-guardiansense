import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/events/domain/event_display.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

SecurityEvent _event({required String title, required String summary}) {
  return SecurityEvent(
    id: '1',
    occurredAt: DateTime(2026, 7, 7, 18, 20),
    title: title,
    summary: summary,
    severity: SecurityEventSeverity.warning,
  );
}

void main() {
  test('traduz padrão pocketExtraction', () {
    final event = _event(
      title: 'Padrão de risco detectado',
      summary: 'pocketExtraction',
    );

    expect(EventDisplay.title(event), 'Padrão detectado: Puxão + tela apagou');
    expect(EventDisplay.subtitle(event), isNull);
  });

  test('traduz transição de risco attention para elevated', () {
    final event = _event(
      title: 'Risco elevado',
      summary: 'risco attention -> elevated',
    );

    expect(
      EventDisplay.subtitle(event),
      'Alerta subiu de atenção para elevado',
    );
  });

  test('shortSummary humaniza texto técnico', () {
    expect(
      EventDisplay.shortSummary('pocketExtraction'),
      'Puxão + tela apagou',
    );
    expect(
      EventDisplay.shortSummary('ostra reaberta · usuário confirmou'),
      'Ostra reaberta',
    );
  });
}
