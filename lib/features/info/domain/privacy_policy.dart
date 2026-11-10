import 'package:flutter/material.dart';

/// Política de Privacidade — mesmo conteúdo e versão do app Guardian Sense
/// (`lib/l10n/app_pt.arb`, chaves `privacyPolicy*`).
///
/// Ao mudar o conteúdo de forma material, incremente [version] junto com o app.
abstract final class PrivacyPolicy {
  static const String version = '1.2';

  static const String title = 'Privacidade';

  static const List<PrivacySection> sections = [
    PrivacySection(
      body:
          'O Guardian Sense prioriza processamento no aparelho. Esta política '
          'explica o que o app usa, o que vai para a nuvem quando você entra '
          'numa conta e como apagar seus dados.',
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
          'Para detectar sinais de furto e proteger apps, o motor usa sensores '
          'e estado do dispositivo: aceleração, movimento (parado, caminhando, '
          'veículo), tela ligada/apagada e bloqueio. Para reconhecer lugares '
          '(Casa, Trabalho, Rua) usa a rede Wi‑Fi conectada — o nome da rede '
          'fica só no aparelho. Logs de eventos ficam localmente para '
          'histórico e calibração.',
    ),
    PrivacySection(
      title: 'Com conta e portal',
      icon: Icons.cloud_outlined,
      body:
          'Sem conta, nada vai para a nuvem. Se você entrar numa conta, o app '
          'sincroniza com a Central de Proteção (portal). A proteção básica '
          'funciona sem login.',
      bullets: [
        'Conta: e-mail, nome e foto do login (Google ou e-mail e senha)',
        'Aparelho: modelo, versão do Android, estado da proteção e da ostra, '
            'situação (Casa, Trabalho, Rua), Wi‑Fi e dados móveis ligados ou '
            'não, e a lista de apps que você protegeu',
        'Localização, com a permissão concedida: posição atual e trilha de '
            'pontos — com o app aberto, pelo escudo em segundo plano e, com '
            'mais frequência, com a ostra fechada (pós-furto)',
        'Eventos de proteção (ostra fechada, alertas, tentativa de remoção) e '
            'comandos remotos do portal',
      ],
    ),
    PrivacySection(
      title: 'Acessibilidade, VPN e contenção',
      icon: Icons.accessibility_new_outlined,
      body:
          'O serviço de acessibilidade, quando ligado, observa só qual app está '
          'em primeiro plano, para bloquear apps protegidos com a ostra fechada '
          '— não lê mensagens, senhas nem o conteúdo da tela. A VPN de '
          'contenção, opcional, roda só no aparelho: bloqueia a rede dos apps '
          'protegidos e não envia seu tráfego a nenhum servidor.',
    ),
    PrivacySection(
      title: 'Serviços que usamos',
      icon: Icons.dns_outlined,
      body:
          'A nuvem roda no Google Firebase (autenticação, banco de dados e '
          'funções), que processa os dados em nosso nome. Usamos também o '
          'Firebase Crashlytics (relatórios de falha) e o Firebase Analytics '
          '(eventos de uso, sem conteúdo pessoal) para corrigir erros e '
          'melhorar o app. Não vendemos dados nem os compartilhamos com '
          'anunciantes.',
    ),
    PrivacySection(
      title: 'Por quanto tempo guardamos',
      icon: Icons.schedule_outlined,
      body:
          'Trilha de localização e eventos: até 90 dias, depois são apagados '
          'automaticamente. Comandos do portal: 7 dias. Dados da conta e do '
          'aparelho: enquanto a conta existir.',
    ),
    PrivacySection(
      title: 'Seus controles',
      icon: Icons.tune_outlined,
      body:
          'Você pode limpar o histórico local e os dados na nuvem pelas '
          'Configurações, e excluir a conta em Perfil → Excluir minha conta '
          '(ou em guardian-sense.com/excluir-conta). A exclusão apaga a conta '
          'e todos os dados na nuvem; guardamos só um código irreversível '
          '(hash) do e-mail, para o período de teste não ser reiniciado, e '
          'registros de pagamento sem vínculo com a conta, por obrigação '
          'fiscal. Você pode desligar o monitoramento e gerenciar permissões '
          'nos ajustes do Android.',
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
