import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';

class EmptyDevicesCard extends StatelessWidget {
  const EmptyDevicesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
           Icon(Icons.smartphone_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Nenhum dispositivo sincronizado',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Abra o Guardian Sense no celular com a mesma conta. '
            'O aparelho registrará automaticamente quando houver internet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
