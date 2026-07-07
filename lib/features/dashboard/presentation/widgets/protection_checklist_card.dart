import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

class ProtectionChecklistCard extends StatelessWidget {
  const ProtectionChecklistCard({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final layout = ProtectionSnapshot.checklistLayout(status);
    final mainWidth = AppLayout.mainAreaWidth(MediaQuery.sizeOf(context).width);
    final twoColumns = mainWidth >= AppLayout.checklistTwoColBreakpoint;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respostas em segundos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            status.isOnline
                ? 'Status em tempo real do aparelho.'
                : 'Último estado conhecido do aparelho.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          if (twoColumns && layout.right.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ChecklistColumn(entries: layout.left)),
                const SizedBox(width: 20),
                Expanded(child: _ChecklistColumn(entries: layout.right)),
              ],
            )
          else
            _ChecklistColumn(entries: [...layout.left, ...layout.right]),
          if (layout.fullWidth.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final entry in layout.fullWidth)
              _ChecklistRow(
                entry: entry,
                fullWidth: true,
                onDetails: entry.answer != 'Nenhuma registrada'
                    ? () => NavigationLoadingScope.of(context)
                        .go(context, AppRoutes.events)
                    : null,
              ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistColumn extends StatelessWidget {
  const _ChecklistColumn({required this.entries});

  final List<ProtectionChecklistEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) _ChecklistRow(entry: entry),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.entry,
    this.fullWidth = false,
    this.onDetails,
  });

  final ProtectionChecklistEntry entry;
  final bool fullWidth;
  final VoidCallback? onDetails;

  static IconData? _iconFor(String question) {
    if (question.startsWith('Meu celular')) return Icons.shield_outlined;
    if (question.startsWith('O Runtime')) return Icons.memory_rounded;
    if (question.startsWith('A Ostra')) return Icons.lock_outline_rounded;
    if (question.startsWith('Quando foi')) return Icons.sync_rounded;
    if (question.startsWith('Último evento')) {
      return Icons.notifications_active_outlined;
    }
    if (question.startsWith('Qual é meu')) return Icons.percent_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.signal) {
      ChecklistSignal.ok => AppColors.trustHigh,
      ChecklistSignal.warn => AppColors.trustMedium,
      ChecklistSignal.alert => AppColors.riskCritical,
      ChecklistSignal.muted => AppColors.textMuted,
    };
    final compact = fullWidth || entry.answer.length > 40;
    final icon = _iconFor(entry.question);

    return Padding(
      padding: EdgeInsets.only(bottom: fullWidth ? 4 : 10, top: fullWidth ? 6 : 0),
      child: Container(
        width: double.infinity,
        padding: fullWidth
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : EdgeInsets.zero,
        decoration: fullWidth
            ? BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: icon != null
                  ? Icon(icon, size: 18, color: color.withValues(alpha: 0.9))
                  : Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.question,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.answer,
                    style: (compact
                            ? Theme.of(context).textTheme.bodySmall
                            : Theme.of(context).textTheme.bodyMedium)
                        ?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (onDetails != null) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onDetails,
                      child: Text(
                        'Ver detalhes →',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
