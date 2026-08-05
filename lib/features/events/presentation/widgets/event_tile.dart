import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/events/domain/event_display.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';
import 'package:intl/intl.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    this.detailCount,
    this.showDate = false,
    this.onTap,
  });

  final SecurityEvent event;
  final int? detailCount;

  /// Quando true (filtros multi-dia), mostra dd/MM junto da hora.
  final bool showDate;
  final VoidCallback? onTap;

  static String formatOccurredAt(DateTime at, {required bool showDate}) {
    final local = at.toLocal();
    return DateFormat(showDate ? 'dd/MM HH:mm:ss' : 'HH:mm:ss').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final color = event.isNormalSession
        ? AppColors.trustHigh
        : severityColor(event.severity);
    final icon = _categoryIcon(event.category);
    final title = EventDisplay.title(event);
    final subtitle = EventDisplay.subtitle(event);
    final status = EventDisplay.statusLabel(event);
    final showDetails = (detailCount ?? 0) > 1;
    final occurredLabel =
        formatOccurredAt(event.occurredAt, showDate: showDate);
    final theme = Theme.of(context);
    final relative = formatRelativeTime(event.occurredAt);
    final narrow = MediaQuery.sizeOf(context).width < 560;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(icon, size: 18, color: color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: occurredLabel,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      TextSpan(
                                        text: '  ·  ',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      TextSpan(
                                        text: status,
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.25,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                                if (narrow) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _SeverityPill(
                                        label: event.severityLabel,
                                        color: color,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        relative,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      if (showDetails) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '$detailCount registros',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!narrow) ...[
                            const SizedBox(width: 12),
                            _TrailingMeta(
                              severityLabel: event.severityLabel,
                              color: color,
                              relative: relative,
                              detailCount: showDetails ? detailCount : null,
                              showChevron: onTap != null,
                            ),
                          ] else if (onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color severityColor(SecurityEventSeverity severity) =>
      switch (severity) {
        SecurityEventSeverity.critical => AppColors.riskCritical,
        SecurityEventSeverity.warning => AppColors.riskElevated,
        SecurityEventSeverity.info => AppColors.trustHigh,
      };

  static IconData _categoryIcon(EventCategory category) => switch (category) {
        EventCategory.oyster => Icons.lock_outline_rounded,
        EventCategory.risk => Icons.warning_amber_rounded,
        EventCategory.protection => Icons.shield_outlined,
        EventCategory.blocked => Icons.block_rounded,
        EventCategory.normal => Icons.verified_user_outlined,
        EventCategory.other => Icons.notifications_active_outlined,
      };
}

/// Meta compacta à direita — uma faixa horizontal, sem coluna alta.
class _TrailingMeta extends StatelessWidget {
  const _TrailingMeta({
    required this.severityLabel,
    required this.color,
    required this.relative,
    required this.showChevron,
    this.detailCount,
  });

  final String severityLabel;
  final Color color;
  final String relative;
  final bool showChevron;
  final int? detailCount;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeverityPill(label: severityLabel, color: color),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(relative, style: muted),
            if (detailCount != null)
              Text(
                '$detailCount registros',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
        if (showChevron) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.textMuted,
          ),
        ],
      ],
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
      ),
    );
  }
}
