import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;

        return GuardianScaffold(
          title: 'Conta',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountSettingsCard(
                title: 'Conta',
                footer:
                    'Sua conta vincula este aparelho e prepara recursos de nuvem. '
                    'A proteção funciona normalmente mesmo sem login.',
                children: [
                  if (user != null) ...[
                    _AccountInfoRow(
                      icon: Icons.verified_user_outlined,
                      text: 'Conectado como ${_shortLabel(user)}',
                    ),
                    if (_emailLine(user) != null) ...[
                      const _AccountRowDivider(),
                      _AccountInfoRow(
                        icon: Icons.mail_outline_rounded,
                        text: _emailLine(user)!,
                      ),
                    ],
                  ] else
                    _AccountNavRow(
                      title: 'Entrar ou criar conta',
                      value: 'Desconectado',
                      onTap: () => context.go(AppRoutes.login),
                    ),
                ],
              ),
              if (user != null) ...[
                const SizedBox(height: 16),
                _AccountSettingsCard(
                  title: 'Sessão',
                  children: [
                    _AccountNavRow(
                      title: 'Sair',
                      value: '',
                      titleColor: AppColors.riskCritical,
                      showChevron: false,
                      onTap: () async {
                        await auth.signOut();
                        if (context.mounted) context.go(AppRoutes.home);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _shortLabel(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final mail = user.email?.trim();
    if (mail != null && mail.isNotEmpty) return mail;
    return 'Conta';
  }

  static String? _emailLine(User user) {
    final mail = user.email?.trim();
    if (mail == null || mail.isEmpty) return null;
    if (_shortLabel(user) == mail) return null;
    return mail;
  }
}

/// Card de configurações — mesmo padrão visual do app mobile.
class _AccountSettingsCard extends StatelessWidget {
  const _AccountSettingsCard({
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            ...children,
            if (footer != null) ...[
              const SizedBox(height: 4),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountNavRow extends StatelessWidget {
  const _AccountNavRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRowDivider extends StatelessWidget {
  const _AccountRowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: AppColors.textMuted.withValues(alpha: 0.15),
    );
  }
}
