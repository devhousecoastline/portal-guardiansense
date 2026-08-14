import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_footer.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/devices/domain/device_pairing.dart';

/// Landing pública do QR — câmera do celular abre esta URL.
///
/// O vínculo em si só acontece no app (`confirmDevicePairing`).
class PairLandingPage extends StatelessWidget {
  const PairLandingPage({super.key, this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final normalized = DevicePairing.parseCode(code);
    final wellFormed =
        normalized != null && DevicePairing.isWellFormedCode(normalized);

    return AuthPageShell(
      stickyFooter: MediaQuery.sizeOf(context).width >= 900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const GuardianLogo(size: 96, breathe: true),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Vincular aparelho',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Abra o Guardian Sense no celular, entre com a mesma conta '
                  'desta Central e escolha Vincular aparelho para confirmar '
                  'a identidade.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (wellFormed) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Código',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    normalized,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Se o app pedir, digite este código. Ele expira em minutos.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  Text(
                    'QR inválido ou expirado. Gere um novo na Central de Proteção.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                const AuthFooter(includeHorizontalPadding: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
