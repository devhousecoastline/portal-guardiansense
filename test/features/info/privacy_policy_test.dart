import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/info/domain/privacy_policy.dart';

void main() {
  test('política replica o conteúdo e a versão do app', () {
    expect(PrivacyPolicy.version, '1.2');
    expect(PrivacyPolicy.title, 'Privacidade');
    expect(PrivacyPolicy.sections, hasLength(9));

    final intro = PrivacyPolicy.sections.first;
    expect(intro.title, isNull);
    expect(intro.bullets, [
      'Sem gravação de áudio',
      'Sem leitura de mensagens, fotos ou notificações de outros apps',
      'Sem venda de dados a anunciantes',
    ]);

    expect(
      PrivacyPolicy.sections.map((s) => s.title).toList(),
      [
        null,
        'No aparelho',
        'Com conta e portal',
        'Acessibilidade, VPN e contenção',
        'Serviços que usamos',
        'Por quanto tempo guardamos',
        'Seus controles',
        'Limites da proteção e responsabilidade',
        'Versão',
      ],
    );
    expect(PrivacyPolicy.sections[2].bullets, hasLength(4));
    expect(
      PrivacyPolicy.sections[6].body,
      contains('guardian-sense.com/excluir-conta'),
    );
    expect(
      PrivacyPolicy.sections.last.body,
      contains('Política versão 1.2'),
    );
  });
}
