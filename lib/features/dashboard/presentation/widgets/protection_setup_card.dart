import 'dart:math' as math;

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
        accentColor: muted
            ? AppColors.textMuted
            : complete
                ? AppColors.trustHigh
                : status.hasSetupChecklist
                    ? AppColors.trustMedium
                    : AppColors.textMuted,
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 12 : 18,
          20,
          compact ? 10 : 14,
        ),
        child: expands
            ? _buildExpandingBody(
                context,
                muted: muted,
                complete: complete,
              )
            : _buildBody(
                context,
                muted: muted,
                complete: complete,
              ),
      ),
    );
  }

  /// Notebook/grade: cabeçalho + timeline no topo; banner/callout colado na base
  /// (evita o verde “subir” quando 6/6 deixa o bloco mais baixo que o pendente).
  Widget _buildExpandingBody(
    BuildContext context, {
    required bool muted,
    required bool complete,
  }) {
    const gap = 8.0;
    const gapSm = 8.0;
    final dense = compact;

    final footer = !status.hasSetupChecklist
        ? null
        : complete
            ? _CompleteBanner(muted: muted, compact: dense)
            : (status.pendingSetupItems.isNotEmpty
                ? _PendingCallout(
                    items: status.pendingSetupItems,
                    compact: dense,
                  )
                : null);

    return Column(
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
        const SizedBox(height: gap),
        if (!status.hasSetupChecklist)
          Text(
            status.isOnline
                ? 'Abra o Guardian Sense no celular com esta conta para '
                    'sincronizar o checklist.'
                : 'Abra o app no celular para sincronizar quando voltar online.',
            style: DashboardTypography.cardSubtitle(context),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _summaryLabel(status, complete: complete, muted: muted),
                  style: DashboardTypography.highlightCaption(
                    context,
                    color: muted
                        ? AppColors.textMuted
                        : (complete
                            ? AppColors.trustHigh
                            : AppColors.trustMedium),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status.hasWifiRadioStatus ||
                  status.hasMobileDataStatus) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _NetworkRadioChips(
                    wifiEnabled: status.wifiEnabled,
                    mobileDataEnabled: status.mobileDataEnabled,
                    muted: muted,
                    compact: dense,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: _SetupTimeline(
                        items: status.protectionSetupItems,
                        muted: muted,
                        compact: dense,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        if (!status.hasSetupChecklist &&
            (status.hasWifiRadioStatus || status.hasMobileDataStatus)) ...[
          const SizedBox(height: gapSm),
          _NetworkRadioChips(
            wifiEnabled: status.wifiEnabled,
            mobileDataEnabled: status.mobileDataEnabled,
            muted: muted,
            compact: dense,
          ),
          const Spacer(),
        ],
        if (footer != null) ...[
          const SizedBox(height: gapSm),
          footer,
        ],
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool muted,
    required bool complete,
  }) {
    final gap = compact ? 8.0 : 14.0;
    final gapSm = compact ? 8.0 : 10.0;

    return Column(
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
        SizedBox(height: gap),
        if (!status.hasSetupChecklist)
          Text(
            status.isOnline
                ? 'Abra o Guardian Sense no celular com esta conta para '
                    'sincronizar o checklist.'
                : 'Abra o app no celular para sincronizar quando voltar online.',
            style: DashboardTypography.cardSubtitle(context),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _summaryLabel(status, complete: complete, muted: muted),
                  style: DashboardTypography.highlightCaption(
                    context,
                    color: muted
                        ? AppColors.textMuted
                        : (complete
                            ? AppColors.trustHigh
                            : AppColors.trustMedium),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status.hasWifiRadioStatus ||
                  status.hasMobileDataStatus) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _NetworkRadioChips(
                    wifiEnabled: status.wifiEnabled,
                    mobileDataEnabled: status.mobileDataEnabled,
                    muted: muted,
                    compact: compact,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: gap),
          _SetupTimeline(
            items: status.protectionSetupItems,
            muted: muted,
            compact: compact,
          ),
          if (!complete && status.pendingSetupItems.isNotEmpty) ...[
            SizedBox(height: gapSm),
            _PendingCallout(
              items: status.pendingSetupItems,
              compact: compact,
            ),
          ],
          if (complete) ...[
            SizedBox(height: gapSm),
            _CompleteBanner(muted: muted, compact: compact),
          ],
        ],
        if (!status.hasSetupChecklist &&
            (status.hasWifiRadioStatus || status.hasMobileDataStatus)) ...[
          SizedBox(height: gapSm),
          _NetworkRadioChips(
            wifiEnabled: status.wifiEnabled,
            mobileDataEnabled: status.mobileDataEnabled,
            muted: muted,
            compact: compact,
          ),
        ],
      ],
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

/// Telemetria Wi‑Fi + dados móveis — não conta no checklist de requisitos.
class _NetworkRadioChips extends StatelessWidget {
  const _NetworkRadioChips({
    required this.wifiEnabled,
    required this.mobileDataEnabled,
    required this.muted,
    required this.compact,
  });

  final bool? wifiEnabled;
  final bool? mobileDataEnabled;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Sem FittedBox: no notebook ele encolhia o Row e os glifos sumiam.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wifiEnabled != null)
          _RadioStatusChip(
            enabled: wifiEnabled!,
            muted: muted,
            compact: compact,
            onLabel: 'Wi‑Fi ligado',
            offLabel: 'Wi‑Fi desligado',
            glyph: _RadioGlyph.wifi,
          ),
        if (wifiEnabled != null && mobileDataEnabled != null)
          const SizedBox(width: 8),
        if (mobileDataEnabled != null)
          _RadioStatusChip(
            enabled: mobileDataEnabled!,
            muted: muted,
            compact: compact,
            onLabel: 'Dados ligados',
            offLabel: 'Dados desligados',
            glyph: _RadioGlyph.mobileData,
          ),
      ],
    );
  }
}

enum _RadioGlyph { wifi, mobileData }

class _RadioStatusChip extends StatelessWidget {
  const _RadioStatusChip({
    required this.enabled,
    required this.muted,
    required this.compact,
    required this.onLabel,
    required this.offLabel,
    required this.glyph,
  });

  final bool enabled;
  final bool muted;
  final bool compact;
  final String onLabel;
  final String offLabel;
  final _RadioGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final accent = muted
        ? AppColors.textMuted
        : enabled
            ? AppColors.trustHigh
            : AppColors.trustMedium;
    final label = enabled ? onLabel : offLabel;
    final size = compact ? 15.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: switch (glyph) {
                _RadioGlyph.wifi => _WifiGlyphPainter(
                    color: accent,
                    enabled: enabled,
                  ),
                _RadioGlyph.mobileData => _MobileDataGlyphPainter(
                    color: accent,
                    enabled: enabled,
                  ),
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Glifo Wi‑Fi desenhado — não depende do subset MaterialIcons no web.
class _WifiGlyphPainter extends CustomPainter {
  _WifiGlyphPainter({required this.color, required this.enabled});

  final Color color;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.12
      ..strokeCap = StrokeCap.round;

    final c = Offset(size.width / 2, size.height * 0.72);
    final maxR = size.shortestSide * 0.55;

    if (enabled) {
      for (final t in [0.38, 0.68, 1.0]) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: maxR * t),
          -math.pi * 0.75,
          math.pi * 0.5,
          false,
          paint,
        );
      }
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: maxR),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
        paint..color = color.withValues(alpha: 0.45),
      );
      final slash = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.22, size.height * 0.22),
        Offset(size.width * 0.78, size.height * 0.78),
        slash,
      );
    }

    canvas.drawCircle(
      c,
      size.shortestSide * 0.08,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _WifiGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.enabled != enabled;
}

/// Glifo de barras de sinal — não depende do subset MaterialIcons no web.
class _MobileDataGlyphPainter extends CustomPainter {
  _MobileDataGlyphPainter({required this.color, required this.enabled});

  final Color color;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const bars = 4;
    final gap = size.width * 0.08;
    final barW = (size.width - gap * (bars - 1)) / bars;
    final maxH = size.height * 0.9;
    final base = size.height;

    for (var i = 0; i < bars; i++) {
      final h = maxH * ((i + 1) / bars);
      final left = i * (barW + gap);
      final active = enabled || i == 0;
      paint.color = active ? color : color.withValues(alpha: 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, base - h, barW, h),
          Radius.circular(barW * 0.35),
        ),
        paint,
      );
    }

    if (!enabled) {
      final slash = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.15, size.height * 0.2),
        Offset(size.width * 0.9, size.height * 0.85),
        slash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MobileDataGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.enabled != enabled;
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
        // my_location já é usado no mapa; gps_fixed some no build web (glyph vazio).
        _SetupKind.location => Icons.my_location,
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
        _SetupKind.location => const Color(0xFFFF8A3D),
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
      case 'location':
      case 'gps':
      case 'localizacao':
        return _SetupKind.location;
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
    if (l.contains('localiza') || l.contains('gps')) {
      return _SetupKind.location;
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
  location,
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
          constraints: BoxConstraints(
            minHeight: CelularSeguroCallout.minHeight(compact: compact),
          ),
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppColors.trustMedium.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.trustMedium.withValues(alpha: 0.28),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisSize: MainAxisSize.min,
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
      alignment: Alignment.centerLeft,
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
