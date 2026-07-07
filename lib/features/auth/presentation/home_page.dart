import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/home_features_showcase.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_institutional_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final wide = width >= 960;
    final contentMaxWidth = wide ? 920.0 : (compact ? 480.0 : 640.0);
    final horizontalPadding = compact ? 24.0 : 48.0;

    return AuthPageShell(
      appBar: const AuthAppBar.home(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 28 : 48,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthBrandHeader(
                        logoSize: compact ? 80 : 96,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 36 : 48),
                      const LoginInstitutionalPanel(
                        creating: false,
                        showFeatures: false,
                        showRuntimeBadge: true,
                        centered: true,
                      ),
                      const SizedBox(height: 28),
                      const HomeFeaturesShowcase(),
                      if (compact) ...[
                        const SizedBox(height: 32),
                        GuardianPillButton(
                          label: 'Entrar',
                          icon: Icons.arrow_forward_rounded,
                          fullWidth: true,
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              context.go('${AppRoutes.login}?criar=1'),
                          child: const Text('Primeiro acesso — criar conta'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
