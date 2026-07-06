import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

class ProtectionSetupCard extends StatelessWidget {
  const ProtectionSetupCard({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações do aparelho',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'O que você já ajustou no app e o que ainda falta para 100%.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (!status.isOnline) ...[
            _InfoBanner(
              text: status.hasSetupChecklist
                  ? 'Aparelho offline — lista abaixo pode estar desatualizada.'
                  : 'Aparelho offline — abra o app no celular para sincronizar.',
            ),
            const SizedBox(height: 12),
          ],
          if (!status.hasSetupChecklist)
            Text(
              'Detalhes ainda não sincronizados. Abra o app Guardian Sense no '
              'celular com a mesma conta para enviar o checklist.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            )
          else ...[
            _ProgressSummary(status: status),
            const SizedBox(height: 20),
            if (status.configuredSetupItems.isNotEmpty) ...[
              _SectionTitle(
                label: 'Ajustado no app',
                color: AppColors.trustHigh,
              ),
              const SizedBox(height: 8),
              ...status.configuredSetupItems.map(
                (item) => _SetupRow(item: item, configured: true),
              ),
            ],
            if (status.pendingSetupItems.isNotEmpty) ...[
              if (status.configuredSetupItems.isNotEmpty)
                const SizedBox(height: 16),
              _SectionTitle(
                label: 'Ainda falta',
                color: AppColors.trustMedium,
              ),
              const SizedBox(height: 8),
              ...status.pendingSetupItems.map(
                (item) => _SetupRow(item: item, configured: false),
              ),
              const SizedBox(height: 8),
              Text(
                'Conclua no app Guardian Sense → Configurações ou onboarding.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final total = status.protectionSetupItems.length;
    final done = status.configuredSetupItems.length;
    final ratio = total == 0 ? 0.0 : done / total;
    final color =
        done == total ? AppColors.trustHigh : AppColors.trustMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$done de $total requisitos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '${status.protectionIndex}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({required this.item, required this.configured});

  final ProtectionSetupItem item;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    final color = configured ? AppColors.trustHigh : AppColors.trustMedium;
    final icon = configured ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  configured ? 'Configurado' : 'Pendente — ajuste no app',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
      ),
    );
  }
}
