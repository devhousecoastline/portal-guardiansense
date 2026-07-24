import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';

class EmptyDevicesCard extends StatelessWidget {
  const EmptyDevicesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smartphone_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 14),
              Text(
                'Nenhum aparelho vinculado a esta conta',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'O portal só mostra proteção e status depois que o app '
                'Guardian Sense está instalado no celular, você entra com '
                'a mesma conta e conclui o onboarding.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'Passos: instalar o app → entrar com este e-mail → '
                'finalizar a configuração inicial. O aparelho aparece aqui '
                'assim que sincronizar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
