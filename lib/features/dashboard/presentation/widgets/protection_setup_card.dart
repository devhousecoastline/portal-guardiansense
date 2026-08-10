import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/widgets/celular_seguro_link.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionSetupCard extends StatelessWidget {
  const ProtectionSetupCard({
    super.key,
    required this.status,
    this.stretchVertically = false,
    this.fillHeight = false,
    this.compact = false,
  });

  final DeviceStatus status;
  final bool stretchVertically;
  final bool fillHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = !status.isOnline;
    final complete = status.hasSetupChecklist &&
        status.pendingSetupItems.isEmpty &&
        status.configuredSetupItems.isNotEmpty;
    // Mesma regra do hero: infinity só no notebook ([fillHeight]).
    final expands = fillHeight;

    return SizedBox(
      width: double.infinity,
      height: expands ? double.infinity : null,
      child: SectionCard(
        expandVertically: expands,
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 12 : 18,
          20,
          compact ? 10 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configurações do aparelho',
              style: DashboardTypography.cardTitle(context, compact: compact),
            ),
            const SizedBox(height: 4),
            Text(
              ProtectionSnapshot.setupCardSubtitle(status),
              style: DashboardTypography.cardSubtitle(context),
            ),
            SizedBox(height: compact ? 10 : 14),
            if (!status.hasSetupChecklist)
              Text(
                status.isOnline
                    ? 'Abra o Guardian Sense no celular com esta conta para '
                        'sincronizar o checklist.'
                    : 'Abra o app no celular para sincronizar quando voltar online.',
                style: DashboardTypography.cardSubtitle(context),
              )
            else ...[
              Text(
                _summaryLabel(status, complete: complete, muted: muted),
                style: DashboardTypography.highlightCaption(
                  context,
                  color: muted
                      ? AppColors.textMuted
                      : (complete
                          ? AppColors.trustHigh
                          : AppColors.trustMedium),
                ),
              ),
              SizedBox(height: compact ? 10 : 14),
              // Divide a folga entre topo e base para centrar a timeline no card.
              if (fillHeight) const Spacer(),
              _SetupTimeline(
                items: status.protectionSetupItems,
                muted: muted,
                compact: compact,
              ),
              if (fillHeight) const Spacer(),
              if (!complete && status.pendingSetupItems.isNotEmpty) ...[
                SizedBox(height: compact ? 10 : 14),
                _PendingCallout(
                  items: status.pendingSetupItems,
                  compact: compact,
                ),
              ],
              if (complete) ...[
                SizedBox(height: compact ? 10 : 14),
                _CompleteBanner(muted: muted, compact: compact),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _summaryLabel(
    DeviceStatus status, {
    required bool complete,
    required bool muted,
  }) {
    final total = status.protectionSetupItems.length;
    final done = status.configuredSetupItems.length;
    if (muted) return 'Última sync: $done de $total requisitos';
    if (complete) return '$done de $total requisitos configurados';
    return '$done de $total requisitos';
  }
}

/// Timeline horizontal: ponto → haste vertical → ícone (tooltip).
class _SetupTimeline extends StatelessWidget {
  const _SetupTimeline({
    required this.items,
    required this.muted,
    required this.compact,
  });

  final List<ProtectionSetupItem> items;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final n = items.length;
    final dot = compact ? 18.0 : 22.0;
    final iconSize = compact ? 18.0 : 20.0;
    final stemH = compact ? 16.0 : 20.0;
    final lineH = compact ? 2.0 : 2.5;

    // Linha entre pontos fica em cada step (sem LayoutBuilder/Stack) para
    // o IntrinsicHeight do Centro desktop funcionar.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: _TimelineStep(
              item: items[i],
              muted: muted,
              dotSize: dot,
              iconSize: iconSize,
              stemHeight: stemH,
              lineHeight: lineH,
              iconFor: _iconFor,
              colorFor: _colorFor,
              index: i,
              total: n,
            ),
          ),
      ],
    );
  }

  static IconData _iconFor(ProtectionSetupItem item) => switch (_kindOf(item)) {
        _SetupKind.notifications => Icons.notifications_outlined,
        _SetupKind.accessibility => Icons.accessibility_new_rounded,
        _SetupKind.battery => Icons.battery_charging_full_rounded,
        _SetupKind.protectedLayers => Icons.layers_outlined,
        _SetupKind.recovery => Icons.fingerprint,
        _SetupKind.unknown => Icons.check_circle_outline,
      };

  /// Cores decorativas — dão identidade a cada requisito sem invadir a escala
  /// semântica de risco (verde/âmbar/vermelho), reservada para estado.
  static Color _colorFor(ProtectionSetupItem item) => switch (_kindOf(item)) {
        _SetupKind.notifications => const Color(0xFF4C9AFF),
        _SetupKind.accessibility => const Color(0xFF9B7BFF),
        _SetupKind.battery => const Color(0xFF2BB8A3),
        _SetupKind.protectedLayers => const Color(0xFF35B6D8),
        _SetupKind.recovery => const Color(0xFFE573B5),
        _SetupKind.unknown => AppColors.primary,
      };

  static _SetupKind _kindOf(ProtectionSetupItem item) {
    switch (item.id) {
      case 'notifications':
        return _SetupKind.notifications;
      case 'accessibility':
        return _SetupKind.accessibility;
      case 'battery':
        return _SetupKind.battery;
      case 'protected_layers':
        return _SetupKind.protectedLayers;
      case 'recovery':
        return _SetupKind.recovery;
    }

    final l = item.label.toLowerCase();
    if (l.contains('notif')) return _SetupKind.notifications;
    if (l.contains('acessib') || l.contains('access')) {
      return _SetupKind.accessibility;
    }
    if (l.contains('bater')) return _SetupKind.battery;
    if (l.contains('camada') || l.contains('layer')) {
      return _SetupKind.protectedLayers;
    }
    if (l.contains('biom') || l.contains('pin') || l.contains('recup')) {
      return _SetupKind.recovery;
    }
    return _SetupKind.unknown;
  }
}

enum _SetupKind {
  notifications,
  accessibility,
  battery,
  protectedLayers,
  recovery,
  unknown,
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.item,
    required this.muted,
    required this.dotSize,
    required this.iconSize,
    required this.stemHeight,
    required this.lineHeight,
    required this.iconFor,
    required this.colorFor,
    required this.index,
    required this.total,
  });

  final ProtectionSetupItem item;
  final bool muted;
  final double dotSize;
  final double iconSize;
  final double stemHeight;
  final double lineHeight;
  final IconData Function(ProtectionSetupItem) iconFor;
  final Color Function(ProtectionSetupItem) colorFor;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final accent = item.done && !muted ? colorFor(item) : AppColors.textMuted;
    final lineColor = AppColors.divider.withValues(alpha: 0.95);

    // Preferir tooltip para dentro do card (baixo) e afastar das bordas laterais.
    final edgePad = index == 0
        ? const EdgeInsets.only(left: 8)
        : index == total - 1
            ? const EdgeInsets.only(right: 8)
            : EdgeInsets.zero;

    return Tooltip(
      message: item.label,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 280),
      verticalOffset: 10,
      margin: edgePad.add(const EdgeInsets.symmetric(horizontal: 10)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: dotSize,
            child: Row(
              children: [
                Expanded(
                  child: index == 0
                      ? const SizedBox.shrink()
                      : Container(
                          height: lineHeight,
                          color: lineColor,
                        ),
                ),
                _TimelineDot(
                  done: item.done,
                  muted: muted,
                  size: dotSize,
                ),
                Expanded(
                  child: index == total - 1
                      ? const SizedBox.shrink()
                      : Container(
                          height: lineHeight,
                          color: lineColor,
                        ),
                ),
              ],
            ),
          ),
          Container(
            width: 2.5,
            height: stemHeight,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: item.done ? 0.85 : 0.5),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Icon(
            iconFor(item),
            size: iconSize,
            color: item.done && !muted
                ? accent
                : AppColors.textMuted.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.done,
    required this.muted,
    required this.size,
  });

  final bool done;
  final bool muted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final okColor = muted ? AppColors.textMuted : AppColors.trustHigh;
    final pendingColor = AppColors.textMuted.withValues(alpha: 0.45);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? okColor : AppColors.card,
        border: Border.all(
          color: done ? okColor : pendingColor,
          width: done ? 0 : 2,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: okColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: done
          ? Icon(
              Icons.check_rounded,
              size: size * 0.62,
              color: Colors.white,
            )
          : null,
    );
  }
}

class _PendingCallout extends StatelessWidget {
  const _PendingCallout({
    required this.items,
    required this.compact,
  });

  final List<ProtectionSetupItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = items.map((i) => i.label).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ajuste no app → Configurações.',
          style: DashboardTypography.mutedLabel(context),
        ),
        SizedBox(height: compact ? 6 : 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppColors.trustMedium.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.trustMedium.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: compact ? 18 : 20,
                color: AppColors.trustMedium,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: DashboardTypography.emphasis(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items.length == 1
                          ? 'Pendente no app'
                          : '${items.length} pendentes no app',
                      style: DashboardTypography.emphasis(
                        context,
                        color: AppColors.trustMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompleteBanner extends StatelessWidget {
  const _CompleteBanner({
    required this.muted,
    required this.compact,
  });

  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = muted ? AppColors.textMuted : AppColors.trustHigh;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: CelularSeguroCallout.minHeight(compact: compact),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            muted ? Icons.history_rounded : Icons.verified_rounded,
            size: compact ? 18 : 20,
            color: accent,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              muted
                  ? 'Checklist completo na última sync (pode estar desatualizado)'
                  : 'Todos os requisitos configurados no app',
              style: DashboardTypography.highlightCaption(
                context,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
