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
    this.onTap,
  });

  final SecurityEvent event;
  final int? detailCount;
  final VoidCallback? onTap;

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

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('HH:mm:ss').format(event.occurredAt),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                          ),
                          const Spacer(),
                          if (onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SeverityPill(label: event.severityLabel, color: color),
                          const SizedBox(width: 8),
                          Text(
                            formatRelativeTime(event.occurredAt),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          ),
                          if (showDetails) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$detailCount registros',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
