import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';

/// Conta do usuário logado — fixo no final do drawer/sidebar (como no app).
class DrawerAccountTile extends StatelessWidget {
  const DrawerAccountTile({
    super.key,
    required this.current,
    this.onClose,
  });

  final String current;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final selected = current == AppRoutes.account;

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;
        final bg = selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent;

        return Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openAccount(context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    _AccountAvatar(user: user),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayLabel(user),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user == null ? 'Desconectado' : 'Ver minha conta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 22,
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

  void _openAccount(BuildContext context) {
    onClose?.call();
    if (current != AppRoutes.account) {
      NavigationLoadingScope.of(context).go(context, AppRoutes.account);
    }
  }

  static String _displayLabel(User? user) {
    if (user == null) return 'Entrar';
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email ?? 'Minha conta';
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.user});

  final User? user;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final photo = user?.photoURL;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.isNotEmpty
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialsFallback(),
            )
          : _initialsFallback(),
    );
  }

  Widget _initialsFallback() {
    final u = user;
    if (u == null) {
      return const Icon(
        Icons.person_outline_rounded,
        color: AppColors.primary,
        size: 22,
      );
    }
    return Center(
      child: Text(
        _initials(u),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  static String _initials(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}
