import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionStatusHero extends StatelessWidget {
  const ProtectionStatusHero({
    super.key,
    required this.status,
    required this.tone,
    this.stretchVertically = false,
    this.fillHeight = false,
    this.compact = false,
  });

  final DeviceStatus status;
  final StatusTone tone;
  final bool stretchVertically;
  final bool fillHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(tone);
    final headline = ProtectionSnapshot.headline(status);
    final offline = !status.isOnline;
    // Badge (e banner offline) já cobrem esses estados — a frase só repete.
    final showHeadline = status.level == ProtectionLevel.partial ||
        status.level == ProtectionLevel.alert ||
        status.level == ProtectionLevel.unknown;
    final indexSize = compact ? 32.0 : 52.0;
    // Só [fillHeight] (notebook) força altura infinita. Em desktop,
    // [stretchVertically] usa IntrinsicHeight — infinity/Spacer quebram o layout.
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
              'Índice de proteção',
              style: DashboardTypography.cardTitle(context, compact: compact),
            ),
            // Só alerta/parcial no subtítulo — o aparelho fica no painel (igual notebook).
            if (!compact && showHeadline) ...[
              const SizedBox(height: 4),
              Text(
                headline,
                style: DashboardTypography.cardSubtitle(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: compact ? 8 : 12),
            // No layout em grade o badge OFFLINE no painel basta;
            // o banner ocupava altura e empurrava o índice.
            if (offline && !fillHeight) ...[
              _OfflineBanner(compact: compact),
              SizedBox(height: compact ? 8 : 10),
            ],
            if (fillHeight)
              Expanded(
                child: _IndexPanel(
                  status: status,
                  tone: tone,
                  accent: accent,
                  offline: offline,
                  indexSize: indexSize,
                  compact: compact,
                  fillHeight: true,
                  showDeviceName: true,
                ),
              )
            else ...[
              if (stretchVertically)
                Divider(
                  height: compact ? 16 : 20,
                  thickness: 1,
                  color: AppColors.divider.withValues(alpha: 0.9),
                ),
              _IndexPanel(
                status: status,
                tone: tone,
                accent: accent,
                offline: offline,
                indexSize: indexSize,
                compact: compact,
                fillHeight: false,
                showDeviceName: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _accent(StatusTone tone) => switch (tone) {
        StatusTone.protected => AppColors.trustHigh,
        StatusTone.warning => AppColors.trustMedium,
        StatusTone.critical => AppColors.riskCritical,
        StatusTone.offline => AppColors.textMuted,
        StatusTone.neutral => AppColors.primary,
      };
}

/// Painel interno no mesmo idioma da Contenção remota.
class _IndexPanel extends StatelessWidget {
  const _IndexPanel({
    required this.status,
    required this.tone,
    required this.accent,
    required this.offline,
    required this.indexSize,
    required this.compact,
    required this.fillHeight,
    required this.showDeviceName,
  });

  final DeviceStatus status;
  final StatusTone tone;
  final Color accent;
  final bool offline;
  final double indexSize;
  final bool compact;
  final bool fillHeight;
  final bool showDeviceName;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusBadge(
          label: status.protectionLabel.toUpperCase(),
          tone: tone,
        ),
        SizedBox(height: compact ? 10 : 14),
        _IndexBlock(
          status: status,
          accent: accent,
          offline: offline,
          indexSize: indexSize,
          compact: compact,
        ),
        if (showDeviceName) ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            status.modelLabel,
            textAlign: TextAlign.center,
            style: DashboardTypography.deviceName(context, compact: compact),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (offline) ...[
          const SizedBox(height: 4),
          Text(
            'na última sincronização',
            textAlign: TextAlign.center,
            style: DashboardTypography.mutedLabel(context),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      height: fillHeight ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact || fillHeight ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: fillHeight
          ? Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: body,
              ),
            )
          : body,
    );
  }
}

class _IndexBlock extends StatelessWidget {
  const _IndexBlock({
    required this.status,
    required this.accent,
    required this.offline,
    required this.indexSize,
    required this.compact,
  });

  final DeviceStatus status;
  final Color accent;
  final bool offline;
  final double indexSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Offline: mostra o último índice conhecido (muted), não um traço vazio.
    final value = offline
        ? status.storedProtectionIndex
        : status.protectionIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: indexSize,
                fontWeight: FontWeight.w700,
                color: accent,
                height: 1,
              ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: compact ? 3 : 6, left: 2),
          child: Text(
            '%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 16 : null,
                ),
          ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aparelho offline no momento',
              style: DashboardTypography.mutedLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}
