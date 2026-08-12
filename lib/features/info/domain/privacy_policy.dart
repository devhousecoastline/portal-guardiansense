import 'package:flutter/material.dart';

/// Política de Privacidade — mesmo conteúdo e versão do app Guardian Sense.
///
/// Ao mudar o conteúdo de forma material, incremente [version] junto com o app.
abstract final class PrivacyPolicy {
  static const String version = '1.1';

  static const String title = 'Privacidade';

  static const List<PrivacySection> sections = [
    PrivacySection(
      body:
          'O Guardian Sense prioriza processamento no aparelho. Esta política '
          'explica o que o app usa e o que pode ir ao portal quando você '
          'conecta uma conta.',
      bullets: [
        'Sem gravação de áudio',
        'Sem leitura de mensagens, fotos ou notificações de outros apps',
        'Sem venda de dados a anunciantes',
      ],
    ),
    PrivacySection(
      title: 'No aparelho',
      icon: Icons.smartphone_outlined,
      body:
          'Para detectar furto e proteger apps, o motor usa sensores e estado '
          'do dispositivo: aceleração, movimento (parado, caminhando, veículo), '
          'tela ligada/apagada e bloqueio. Logs de eventos ficam localmente '
          '(Isar) para histórico e calibração.',
    ),
    PrivacySection(
      title: 'Com conta e portal',
      icon: Icons.cloud_outlined,
      body:
          'Se você entrar na conta, o app pode sincronizar com o portal: '
          'eventos de proteção, estado do aparelho, comandos remotos e — se '
          'você ativar localização de emergência — posição em crise (ostra '
          'fechada). A proteção básica funciona sem login.',
    ),
    PrivacySection(
      title: 'Acessibilidade e contenção',
      icon: Icons.accessibility_new_outlined,
      body:
          'O serviço de acessibilidade, quando ligado, observa o app em '
          'primeiro plano só para bloquear apps protegidos com a ostra '
          'fechada. Não é usado para ler conteúdo de mensagens ou senhas.',
    ),
    PrivacySection(
      title: 'Seus controles',
      icon: Icons.tune_outlined,
      body:
          'Você pode limpar o histórico local e, com conta, os dados na nuvem '
          'pelas Configurações. Pode desligar o monitoramento e gerenciar '
          'permissões nos ajustes do Android.',
    ),
    PrivacySection(
      title: 'Limites da proteção e responsabilidade',
      icon: Icons.gavel_outlined,
      body:
          'O Guardian Sense reduz o risco de uso indevido no aparelho após um '
          'furto detectado, mas não garante segurança absoluta. O app não se '
          'responsabiliza por dados obtidos por meios externos à proteção '
          'oferecida — por exemplo engenharia reversa, exploração de '
          'vulnerabilidades do sistema operacional, malware, acesso físico '
          'avançado, clonagem de chip, ou qualquer técnica fora do controle '
          'razoável do aplicativo. Contas bancárias e serviços de terceiros '
          'seguem as regras e canais de segurança desses provedores.',
    ),
    PrivacySection(
      title: 'Versão',
      icon: Icons.history_outlined,
      body:
          'Política versão $version. Texto sujeito a revisão jurídica; '
          'atualizações relevantes pedirão novo aceite no app.',
    ),
  ];
}

final class PrivacySection {
  const PrivacySection({
    this.title,
    this.icon,
    required this.body,
    this.bullets = const [],
  });

  final String? title;
  final IconData? icon;
  final String body;
  final List<String> bullets;
}
