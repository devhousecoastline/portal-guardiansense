import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

enum ChecklistSignal { ok, warn, alert, muted }

class ProtectionChecklistEntry {
  const ProtectionChecklistEntry({
    required this.question,
    required this.answer,
    required this.signal,
    this.fullWidth = false,
  });

  final String question;
  final String answer;
  final ChecklistSignal signal;
  final bool fullWidth;
}

/// Agrupamento do checklist para layout em colunas.
class ChecklistLayout {
  const ChecklistLayout({
    required this.left,
    required this.right,
    this.fullWidth = const [],
  });

  final List<ProtectionChecklistEntry> left;
  final List<ProtectionChecklistEntry> right;
  final List<ProtectionChecklistEntry> fullWidth;
}

/// Respostas rápidas derivadas do [DeviceStatus] sincronizado pelo app.
abstract final class ProtectionSnapshot {
  static String headline(DeviceStatus status) => switch (status.level) {
        ProtectionLevel.protected => 'Seu celular está protegido.',
        ProtectionLevel.partial => 'Proteção parcial — revise os itens abaixo.',
        ProtectionLevel.alert => 'Atenção — proteção comprometida.',
        ProtectionLevel.offline => 'Dispositivo offline no momento.',
        ProtectionLevel.unknown => 'Aguardando dados do aparelho.',
      };

  static StatusTone tone(DeviceStatus status) => switch (status.level) {
        ProtectionLevel.protected => StatusTone.protected,
        ProtectionLevel.partial => StatusTone.warning,
        ProtectionLevel.alert => StatusTone.critical,
        ProtectionLevel.offline => StatusTone.offline,
        ProtectionLevel.unknown => StatusTone.neutral,
      };

  static List<ProtectionChecklistEntry> checklist(DeviceStatus status) {
    final entries = <ProtectionChecklistEntry>[
      ProtectionChecklistEntry(
        question: 'Meu celular está protegido?',
        answer: _protectedAnswer(status),
        signal: _protectedSignal(status),
      ),
      ProtectionChecklistEntry(
        question: 'O Runtime está ativo?',
        answer: _runtimeAnswer(status),
        signal: _runtimeSignal(status),
      ),
      ProtectionChecklistEntry(
        question: 'A Ostra está aberta ou fechada?',
        answer: _oysterAnswer(status),
        signal: _oysterSignal(status),
      ),
      ProtectionChecklistEntry(
        question: 'Quando foi a última sincronização?',
        answer: formatRelativeTime(status.lastSeen),
        signal: status.isOnline ? ChecklistSignal.ok : ChecklistSignal.alert,
      ),
      ProtectionChecklistEntry(
        question: 'Último evento de segurança',
        answer: _recentEventAnswer(status),
        signal: _recentEventSignal(status),
      ),
    ];

    if (!status.hasSetupChecklist) {
      entries.add(
        ProtectionChecklistEntry(
          question: 'Qual é meu Índice de Proteção?',
          answer: _protectionIndexAnswer(status),
          signal: _protectionIndexSignal(status),
        ),
      );
    }

    return entries;
  }

  /// Coluna esq.: proteção + runtime · dir.: ostra + sync · largura total: evento.
  static ChecklistLayout checklistLayout(DeviceStatus status) {
    final all = checklist(status);
    ProtectionChecklistEntry? pick(String prefix) {
      for (final e in all) {
        if (e.question.startsWith(prefix)) return e;
      }
      return null;
    }

    final left = [
      pick('Meu celular'),
      pick('O Runtime'),
    ].whereType<ProtectionChecklistEntry>().toList();

    final right = [
      pick('A Ostra'),
      pick('Quando foi'),
    ].whereType<ProtectionChecklistEntry>().toList();

    final fullWidth = [
      pick('Último evento'),
    ].whereType<ProtectionChecklistEntry>().toList();

    // Fallback se ordem mudar — distribui o que sobrou.
    final placed = {...left, ...right, ...fullWidth};
    final rest = all.where((e) => !placed.contains(e)).toList();
    if (rest.isNotEmpty) {
      left.addAll(rest.where((e) => !e.fullWidth));
    }

    return ChecklistLayout(left: left, right: right, fullWidth: fullWidth);
  }

  static String setupCardSubtitle(DeviceStatus status) {
    if (!status.isOnline) {
      return 'Último estado sincronizado — aparelho offline agora.';
    }
    if (!status.hasSetupChecklist) {
      return 'Aguardando checklist do app.';
    }
    final complete = status.pendingSetupItems.isEmpty &&
        status.configuredSetupItems.isNotEmpty;
    if (complete) return 'Todos os requisitos do app estão em dia.';
    return 'O que falta ajustar no app para chegar a 100%.';
  }

  static String dashboardFooter(DeviceStatus status) {
    if (!status.isOnline) {
      return 'Dados abaixo refletem a última sincronização do aparelho.';
    }
    return 'O celular detecta, decide e bloqueia. '
        'O portal apenas reflete o que foi sincronizado.';
  }

  static String _protectedAnswer(DeviceStatus status) => switch (status.level) {
        ProtectionLevel.protected => 'Sim — ${status.protectionLabel}',
        ProtectionLevel.partial => 'Parcialmente',
        ProtectionLevel.alert => 'Não — verifique o aparelho',
        ProtectionLevel.offline => 'Offline',
        ProtectionLevel.unknown => 'Aguardando sync',
      };

  static ChecklistSignal _protectedSignal(DeviceStatus status) =>
      switch (status.level) {
        ProtectionLevel.protected => ChecklistSignal.ok,
        ProtectionLevel.partial => ChecklistSignal.warn,
        ProtectionLevel.alert => ChecklistSignal.alert,
        ProtectionLevel.offline => ChecklistSignal.muted,
        ProtectionLevel.unknown => ChecklistSignal.muted,
      };

  static String _runtimeAnswer(DeviceStatus status) {
    if (!status.isOnline) return 'Indisponível — dispositivo offline';
    return switch (status.runtimeActive) {
      true => 'Sim — ativo',
      false => 'Não — inativo',
      null => 'Aguardando sync',
    };
  }

  static ChecklistSignal _runtimeSignal(DeviceStatus status) {
    if (!status.isOnline) return ChecklistSignal.muted;
    return switch (status.runtimeActive) {
      true => ChecklistSignal.ok,
      false => ChecklistSignal.alert,
      null => ChecklistSignal.muted,
    };
  }

  static String _oysterAnswer(DeviceStatus status) => switch (status.oysterClosed) {
        true => 'Fechada — contenção ativa',
        false => 'Aberta — uso normal',
        null => 'Aguardando sync',
      };

  static ChecklistSignal _oysterSignal(DeviceStatus status) =>
      switch (status.oysterClosed) {
        true => ChecklistSignal.warn,
        false => ChecklistSignal.ok,
        null => ChecklistSignal.muted,
      };

  static String _recentEventAnswer(DeviceStatus status) {
    if (status.lastEventSummary != null && status.lastEventSummary!.isNotEmpty) {
      final when = formatRelativeTime(status.lastEventAt);
      return '${_shortEventSummary(status.lastEventSummary!)} · $when';
    }
    if (status.lastAlertSummary != null && status.lastAlertSummary!.isNotEmpty) {
      final when = formatRelativeTime(status.lastAlertAt);
      return '${_shortEventSummary(status.lastAlertSummary!)} · $when';
    }
    return 'Nenhuma registrada';
  }

  static String _shortEventSummary(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('ostra reaberta')) return 'Ostra reaberta';
    if (lower.contains('bloqueado')) return 'App bloqueado';
    if (lower.contains('proteção acionada')) return 'Proteção acionada';
    if (lower.contains('ostra fechada')) return 'Ostra fechada';
    final part = raw.split('·').first.trim();
    if (part.length <= 36) return part;
    return '${part.substring(0, 33)}…';
  }

  static ChecklistSignal _recentEventSignal(DeviceStatus status) {
    if (!_hasRecordedEvent(status)) return ChecklistSignal.ok;

    final at = status.lastEventAt ?? status.lastAlertAt;
    final summary = (status.lastEventSummary ?? status.lastAlertSummary ?? '')
        .toLowerCase();

    final critical = summary.contains('bloqueado') ||
        summary.contains('proteção acionada') ||
        summary.contains('ostra fechada');

    if (critical && _isVeryRecent(at)) return ChecklistSignal.alert;
    if (critical && _isRecent(at)) return ChecklistSignal.warn;
    if (_isVeryRecent(at)) return ChecklistSignal.warn;

    final calmNow = status.level == ProtectionLevel.protected &&
        status.oysterClosed != true &&
        status.isOnline;
    if (calmNow) return ChecklistSignal.muted;

    if (_isRecent(at)) return ChecklistSignal.warn;
    return ChecklistSignal.ok;
  }

  static bool _hasRecordedEvent(DeviceStatus status) {
    final event = status.lastEventSummary;
    final alert = status.lastAlertSummary;
    return (event != null && event.isNotEmpty) ||
        (alert != null && alert.isNotEmpty);
  }

  static bool _isVeryRecent(DateTime? at) {
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(minutes: 15);
  }

  static bool _isRecent(DateTime? at) {
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(hours: 24);
  }

  static String _protectionIndexAnswer(DeviceStatus status) {
    final percent = '${status.protectionIndex}%';
    if (!status.hasSetupChecklist) return percent;
    final pending = status.pendingSetupItems.length;
    if (pending == 0) return '$percent — todos os requisitos ok';
    final missing = status.pendingSetupItems.map((i) => i.label).join(', ');
    return '$percent — falta: $missing';
  }

  static ChecklistSignal _protectionIndexSignal(DeviceStatus status) {
    if (status.protectionIndex >= 90) return ChecklistSignal.ok;
    if (status.protectionIndex >= 50) return ChecklistSignal.warn;
    return ChecklistSignal.alert;
  }
}
