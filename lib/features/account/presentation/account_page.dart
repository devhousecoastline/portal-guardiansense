import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

/// Minha conta — layout alinhado ao app mobile (`ProfilePage`).
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
          title: 'Minha conta',
          child: user == null
              ? const _SignedOutView()
              : _ProfileView(user: user, onSignOut: () async {
                  await auth.signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                }),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.user,
    required this.onSignOut,
  });

  final User user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final providers = user.providerData
        .map((p) => p.providerId)
        .where((id) => id.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Center(child: _Avatar(user: user)),
        const SizedBox(height: 16),
        Text(
          _shortLabel(user),
          textAlign: TextAlign.center,
          style:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
           SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.email!,
                  textAlign: TextAlign.center,
                  style:  TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
               SizedBox(width: 6),
              Icon(
                user.emailVerified
                    ? Icons.verified_outlined
                    : Icons.error_outline,
                size: 20,
                color: user.emailVerified
                    ? AppColors.trustHigh
                    : AppColors.riskElevated,
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _ProvidersRow(providers: providers),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Informações da conta',
          children: [
            _InfoTile(
              icon: Icons.smartphone_outlined,
              label: 'Aparelho',
              valueWidget: _LinkedDeviceValue(uid: user.uid),
            ),
            _InfoTile(
              icon: Icons.mail_outline,
              label: 'E-mail',
              value: user.email ?? '—',
            ),
            _InfoTile(
              icon: user.emailVerified
                  ? Icons.verified_outlined
                  : Icons.mark_email_unread_outlined,
              label: 'E-mail verificado',
              valueWidget: Padding(
                padding:  EdgeInsets.only(top: 2),
                child: Icon(
                  user.emailVerified ? Icons.check_circle : Icons.cancel,
                  size: 22,
                  color: user.emailVerified
                      ? AppColors.trustHigh
                      : AppColors.riskCritical,
                ),
              ),
            ),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Conta criada em',
              value: _formatDate(user.metadata.creationTime),
            ),
            _InfoTile(
              icon: Icons.login_outlined,
              label: 'Último acesso',
              value: _formatDateTime(user.metadata.lastSignInTime),
            ),
          ],
        ),
         SizedBox(height: 20),
         Text(
          'Sua conta mantém este aparelho vinculado e prepara os recursos de '
          'nuvem. A proteção anti-furto funciona 100% no aparelho.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
         SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: onSignOut,
            icon:  Icon(Icons.logout_outlined, size: 20),
            label:  Text('Sair da conta'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.riskCritical,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    final photo = user.photoURL;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.trustHigh.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.trustHigh.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initials(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            )
          : _initials(),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        _userInitials(user),
        style:  TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.trustHigh,
        ),
      ),
    );
  }
}

class _ProvidersRow extends StatelessWidget {
  const _ProvidersRow({required this.providers});

  final List<String> providers;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: providers.map(_chip).toList(),
    );
  }

  Widget _chip(String providerId) {
    final (label, icon) = _providerInfo(providerId);
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.trustHigh),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(value != null || valueWidget != null);

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.trustHigh),
           SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:  TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedDeviceValue extends StatelessWidget {
  const _LinkedDeviceValue({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    return StreamBuilder<GuardianDevice?>(
      stream: DeviceRepository().watchPrimaryDevice(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Text('—', style: valueStyle);
        }
        final device = snapshot.data;
        final label = device?.status.modelLabel.trim();
        final text =
            (label != null && label.isNotEmpty) ? label : '—';
        return Text(text, style: valueStyle);
      },
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:  EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 88,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
             SizedBox(height: 16),
             Text(
              'Você ainda não entrou',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
             SizedBox(height: 8),
             Text(
              'Entre ou crie uma conta para vincular este aparelho e preparar '
              'recursos de nuvem. A proteção funciona mesmo sem login.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                height: 1.45,
              ),
            ),
             SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.login),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.trustHigh,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Entrar ou criar conta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

(String, IconData) _providerInfo(String providerId) {
  switch (providerId) {
    case 'google.com':
      return ('Google', Icons.g_mobiledata);
    case 'password':
      return ('E-mail e senha', Icons.mail_outline);
    case 'phone':
      return ('Telefone', Icons.phone_outlined);
    case 'apple.com':
      return ('Apple', Icons.apple);
    case 'facebook.com':
      return ('Facebook', Icons.facebook);
    default:
      return (providerId, Icons.verified_user_outlined);
  }
}

String _shortLabel(User user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final mail = user.email?.trim();
  if (mail != null && mail.isNotEmpty) return mail;
  return 'Conta';
}

String _userInitials(User user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) {
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
  final mail = user.email?.trim();
  if (mail != null && mail.isNotEmpty) return mail.substring(0, 1).toUpperCase();
  return '?';
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  return '$d/$m/$y';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} às $h:$min';
}
