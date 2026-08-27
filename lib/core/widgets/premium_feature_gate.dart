import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/premium_badge.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/account/data/user_repository.dart';
import 'package:guardian_portal/features/account/domain/user_plan.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';

/// Bloqueia conteúdo quando o plano não inclui o recurso.
class PremiumFeatureGate extends StatelessWidget {
  const PremiumFeatureGate({
    super.key,
    required this.featureName,
    required this.hasAccess,
    required this.child,
    this.scaffoldTitle,
    this.scaffoldSubtitle,
    this.onRefresh,
  });

  final String featureName;
  final bool Function(UserPlan plan) hasAccess;
  final Widget child;
  final String? scaffoldTitle;
  final String? scaffoldSubtitle;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final uid = AuthScope.of(context).user?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<UserPlan>(
      stream: UserRepository().watchPlan(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          if (scaffoldTitle != null) {
            return GuardianScaffold(
              title: scaffoldTitle!,
              subtitle: scaffoldSubtitle,
              onRefresh: onRefresh,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        final plan = snap.data ?? UserPlan.free;
        if (hasAccess(plan)) return child;

        final locked = _LockedFeatureCard(featureName: featureName);
        if (scaffoldTitle != null) {
          return GuardianScaffold(
            title: scaffoldTitle!,
            subtitle: scaffoldSubtitle,
            onRefresh: onRefresh,
            child: locked,
          );
        }
        return locked;
      },
    );
  }
}

class _LockedFeatureCard extends StatelessWidget {
  const _LockedFeatureCard({required this.featureName});

  final String featureName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: AppColors.trustMedium.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          featureName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const PremiumBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Disponível no plano Premium ativo. '
                      'Assine para desbloquear este recurso na Central de Proteção.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.premium),
            icon: const Icon(Icons.workspace_premium_outlined, size: 20),
            label: const Text('Assinar Premium'),
          ),
        ],
      ),
    );
  }
}
