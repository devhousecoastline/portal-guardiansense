import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';

/// Recursos exclusivos do plano Premium ativo (`subscription.status == active`).
abstract final class PremiumFeatures {
  /// Linha do tempo de eventos de segurança.
  static bool events(UserPlan plan) => plan.isEntitled;

  /// Mapa e última posição conhecida do aparelho.
  static bool locate(UserPlan plan) => plan.isEntitled;

  /// Comando remoto para proteger todos os apps fora da lista.
  static bool remoteProtectAll(UserPlan plan) => plan.isEntitled;

  /// Proteger o 2º+ app remotamente na mesma camada (o 1º é free).
  static bool remoteProtectExtra(UserPlan plan) => plan.isEntitled;

  /// Fechar ostra remotamente (contenção de emergência).
  static bool closeOyster(UserPlan plan) => plan.isEntitled;

  static bool isNavLocked(String route, UserPlan plan) => switch (route) {
        AppRoutes.events || AppRoutes.locate => !plan.isEntitled,
        _ => false,
      };
}
