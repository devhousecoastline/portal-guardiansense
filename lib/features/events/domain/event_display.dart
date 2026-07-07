import 'package:guardian_portal/features/events/domain/security_event.dart';

/// Textos amigáveis para eventos vindos do app (evita jargão técnico/inglês).
abstract final class EventDisplay {
  static String title(SecurityEvent event) {
    final summary = humanizeSummary(event.summary);
    final rawTitle = event.title.trim();

    if (_isPatternTitle(rawTitle) && summary != null && summary.isNotEmpty) {
      return 'Padrão detectado: $summary';
    }

    return _humanizeTitle(rawTitle);
  }

  /// Detalhe exibido abaixo do título; null quando não há texto útil.
  static String? subtitle(SecurityEvent event) {
    final summary = humanizeSummary(event.summary);
    if (summary != null && summary.isNotEmpty) {
      final displayTitle = title(event);
      if (displayTitle.contains(summary)) return null;
      return summary;
    }
    return _fallbackSubtitle(event);
  }

  static String? humanizeSummary(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    final pattern = _patternLabel(text);
    if (pattern != null) return pattern;

    final levels = _parseRiskTransition(text);
    if (levels != null) {
      return 'Alerta subiu de ${levels.$1} para ${levels.$2}';
    }

    if (text.toLowerCase().startsWith('actions:')) {
      return 'Ações de proteção aplicadas nesta sessão';
    }

    final lower = text.toLowerCase();
    if (lower == 'aguardando confirmação critical') {
      return 'Aguardando confirmação de risco crítico';
    }
    if (lower == 'critical confirmado') {
      return 'Ameaça crítica confirmada pelo motor';
    }

    final spike = RegExp(r'spike\s+([\d.]+)', caseSensitive: false)
        .firstMatch(text);
    if (spike != null) {
      return 'Impacto de ${spike.group(1)} m/s² registrado';
    }

    if (text.startsWith('tela ')) {
      return _humanizeScreenTransition(text);
    }
    if (text.startsWith('movimento')) {
      return _humanizeMotionTransition(text);
    }

    if (!_looksTechnical(text)) return text;
    return 'Sequência registrada pelo motor de proteção';
  }

  /// Resumo curto para dashboard e chips.
  static String shortSummary(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('ostra reaberta')) return 'Ostra reaberta';
    if (lower.contains('bloqueado')) return 'App bloqueado';
    if (lower.contains('proteção acionada')) return 'Proteção acionada';
    if (lower.contains('ostra fechada')) return 'Ostra fechada';

    final human = humanizeSummary(raw);
    if (human != null && human.isNotEmpty) return human;

    final part = raw.split('·').first.trim();
    if (part.length <= 40) return part;
    return '${part.substring(0, 37)}…';
  }

  static String _humanizeTitle(String title) => switch (title) {
        'Padrão de risco detectado' => 'Padrão de furto identificado',
        'Risco crítico confirmado' => 'Risco crítico confirmado',
        'Risco elevado' => 'Movimento brusco analisado',
        _ => title,
      };

  /// Rótulo curto no estilo do app (ex.: RISCO ELEVADO).
  static String statusLabel(SecurityEvent event) {
    if (event.isNormalSession) return 'TUDO NORMAL';
    final title = event.title.toLowerCase();
    if (title.contains('crítico') || title.contains('critico')) {
      return 'RISCO CRÍTICO';
    }
    if (title.contains('padrão')) return 'DETECÇÃO';
    if (title.contains('proteção acionada')) return 'AÇÃO DE PROTEÇÃO';
    if (title.contains('ostra fechada')) return 'CONTENÇÃO';
    if (title.contains('ostra reaberta')) return 'RECUPERAÇÃO';
    if (title.contains('bloqueado')) return 'BLOQUEIO';
    if (title.contains('risco elevado') || title.contains('movimento brusco')) {
      return 'RISCO ELEVADO';
    }
    return event.severityLabel.toUpperCase();
  }

  static String? _fallbackSubtitle(SecurityEvent event) {
    final t = event.title.toLowerCase();
    if (t.contains('risco crítico')) {
      return 'Ameaça confirmada pelo motor de proteção';
    }
    if (t.contains('risco elevado') || t.contains('movimento brusco')) {
      return 'Aguardando mais sinais para confirmar ameaça';
    }
    if (t.contains('proteção acionada')) {
      return 'Ações de proteção aplicadas no aparelho';
    }
    return null;
  }

  static bool _isPatternTitle(String title) {
    final lower = title.toLowerCase();
    return lower.contains('padrão') && lower.contains('risco');
  }

  static String? _patternLabel(String text) {
    return switch (text) {
      'snatchFromHand' => 'Puxão da mão',
      'grabAndRun' => 'Retirada + fuga',
      'pocketExtraction' => 'Puxão + tela apagou',
      'suspiciousMotion' => 'Movimento suspeito',
      _ => null,
    };
  }

  static (String, String)? _parseRiskTransition(String summary) {
    final match = RegExp(
      r'risco\s+(\w+)\s*(?:→|->)\s*(\w+)',
      caseSensitive: false,
    ).firstMatch(summary);
    if (match == null) return null;
    return (
      _riskLevelLabel(match.group(1)!),
      _riskLevelLabel(match.group(2)!),
    );
  }

  static String _riskLevelLabel(String raw) => switch (raw.toLowerCase()) {
        'safe' => 'normal',
        'attention' => 'atenção',
        'elevated' => 'elevado',
        'critical' => 'crítico',
        _ => raw,
      };

  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('snatch') ||
        lower.contains('grabandrun') ||
        lower.contains('pocketextraction') ||
        lower.contains('suspiciousmotion') ||
        lower.contains('critical confirmado') ||
        lower.contains('aguardando confirmação critical');
  }

  static String? _humanizeScreenTransition(String text) {
    if (text.contains('→off') || text.contains('->off') || text.contains('→ off')) {
      return 'Tela apagou durante o evento';
    }
    if (text.contains('→locked') || text.contains('->locked')) {
      return 'Tela bloqueada durante o evento';
    }
    if (text.contains('→on') ||
        text.contains('->on') ||
        text.contains('→unlocked')) {
      return 'Tela ligou durante o evento';
    }
    return 'Mudança de estado da tela';
  }

  static String? _humanizeMotionTransition(String text) {
    final motion = text.replaceFirst(RegExp(r'movimento\s*→\s*'), '').trim();
    if (motion.isEmpty) return 'Mudança de movimento detectada';
    return 'Movimento: ${_motionLabel(motion)}';
  }

  static String _motionLabel(String raw) => switch (raw.toLowerCase()) {
        'idle' => 'parado',
        'walking' => 'caminhando',
        'running' => 'correndo',
        'invehicle' => 'em veículo',
        _ => raw,
      };
}
