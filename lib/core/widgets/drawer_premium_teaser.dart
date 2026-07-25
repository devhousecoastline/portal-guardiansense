import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/subscription/data/subscription_repository.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_entitlement.dart';

/// Teaser do plano premium — status real + navegação para PIX.
class DrawerPremiumTeaser extends StatelessWidget {
  const DrawerPremiumTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthScope.of(context).user?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<SubscriptionEntitlement?>(
      stream: SubscriptionRepository().watchEntitlement(uid),
      builder: (context, snap) {
        final entitlement = snap.data;
        final now = DateTime.now();
        final status = entitlement?.effectiveStatusAt(now);
        final subtitle = switch (status) {
          SubscriptionStatus.trial =>
            'Restam ${entitlement!.trialDaysLeftCeil(now)} dias',
          SubscriptionStatus.active => 'Ativo',
          SubscriptionStatus.expired || SubscriptionStatus.lapsed => 'Assine',
          null => 'Assinatura anual',
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final router = GoRouter.of(context);
                final nav = Navigator.maybeOf(context);
                if (nav != null && nav.canPop()) {
                  nav.pop();
                }
                router.go(AppRoutes.premium);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      status == SubscriptionStatus.active
                          ? Icons.verified_outlined
                          : Icons.star_outline_rounded,
                      color: AppColors.trustMedium.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guardian Premium',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
