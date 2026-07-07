import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthAppBar.home({super.key}) : _variant = _AuthAppBarVariant.home;

  const AuthAppBar.login({super.key}) : _variant = _AuthAppBarVariant.login;

  final _AuthAppBarVariant _variant;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.divider),
      ),
      leading: _variant == _AuthAppBarVariant.login
          ? IconButton(
              tooltip: 'Voltar',
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GuardianLogo(size: 28),
          const SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
      actions: [
        if (_variant == _AuthAppBarVariant.home)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GuardianPillButton(
                label: 'Entrar',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go(AppRoutes.login),
              ),
            ),
          ),
      ],
    );
  }
}

enum _AuthAppBarVariant { home, login }
