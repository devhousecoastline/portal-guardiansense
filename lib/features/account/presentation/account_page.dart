import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/device_verified_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_link_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/devices/data/device_pairing_repository.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/subscription/data/subscription_repository.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_entitlement.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_pricing.dart';
import 'package:intl/intl.dart';

/// Minha conta — cards no mesmo idioma de Configurações e Dispositivos.
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
          subtitle: 'Acesso, plano e dados vinculados ao aparelho',
          child: user == null
              ? const _SignedOutCard()
              : _ProfileView(
                  user: user,
                  onSignOut: () async {
                    await auth.signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user, required this.onSignOut});

  final User user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(user: user),
        const SizedBox(height: 16),
        _PlanCard(uid: user.uid),
        const SizedBox(height: 16),
        _AccountInfoCard(user: user),
        const SizedBox(height: 10),
        const _AccountFootnote(),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Sair da conta'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.riskCritical,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cabeçalho no formato dos tiles: strip colorida, avatar e três linhas.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = user.emailVerified;
    final color = verified ? AppColors.trustHigh : AppColors.riskElevated;
    final providers = user.providerData
        .map((p) => p.providerId)
        .where((id) => id.isNotEmpty)
        .map((id) => _providerInfo(id).$1)
        .toList();
    final narrow = MediaQuery.sizeOf(context).width < 560;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      _Avatar(user: user, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _shortLabel(user),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email?.trim().isNotEmpty == true
                                  ? user.email!
                                  : 'Sem e-mail cadastrado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (providers.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Entrada por ${providers.join(' · ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.25,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!narrow) ...[
                        const SizedBox(width: 12),
                        DeviceVerifiedChip(
                          compact: true,
                          verified: verified,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
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
              errorBuilder: (_, _, _) => _initials(context),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            )
          : _initials(context),
    );
  }

  Widget _initials(BuildContext context) {
    return Center(
      child: Text(
        _userInitials(user),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.trustHigh,
            ),
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.uid});

  final String uid;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _resetting = false;
  bool _resettingVerification = false;

  Future<void> _resetTrial() async {
    if (_resetting) return;
    setState(() => _resetting = true);
    try {
      await SubscriptionRepository().resetTrial(widget.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trial reiniciado: +7 dias.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível resetar o trial: $error')),
      );
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _resetVerification() async {
    if (_resettingVerification) return;
    setState(() => _resettingVerification = true);
    try {
      final n = await DevicePairingRepository().resetVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? 'Nenhum aparelho para resetar.'
                : 'Verificação removida ($n). O Centro volta ao QR.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_verificationResetError(error)),
        ),
      );
    } finally {
      if (mounted) setState(() => _resettingVerification = false);
    }
  }

  static String _verificationResetError(Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'not-found' || error.code == 'NOT_FOUND') {
        return 'Function ainda não publicada. Faça deploy de functions.';
      }
      final raw = (error.message ?? error.code).trim();
      if (raw.isNotEmpty) return raw;
    }
    return 'Não foi possível resetar a verificação.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<SubscriptionEntitlement?>(
      stream: SubscriptionRepository().watchEntitlement(widget.uid),
      builder: (context, snap) {
        final entitlement = snap.data;
        final now = DateTime.now();
        final status = entitlement?.effectiveStatusAt(now);
        final df = DateFormat('dd/MM/yyyy');

        final (label, detail, cta, pillIcon) = switch (status) {
          SubscriptionStatus.trial => (
              'Trial',
              'Restam ${entitlement!.trialDaysLeftCeil(now)} dia'
                  '${entitlement.trialDaysLeftCeil(now) == 1 ? '' : 's'} grátis.',
              'Assinar com PIX',
              Icons.timelapse_rounded,
            ),
          SubscriptionStatus.active => (
              'Ativo',
              entitlement!.expiresAt != null
                  ? 'Até ${df.format(entitlement.expiresAt!.toLocal())}'
                      '${entitlement.store != null ? ' · ${entitlement.store}' : ''}'
                  : 'Assinatura anual ativa.',
              'Ver plano',
              Icons.workspace_premium_outlined,
            ),
          SubscriptionStatus.expired => (
              'Trial encerrado',
              'Assine para continuar com a proteção completa.',
              'Assinar com PIX',
              Icons.hourglass_disabled_outlined,
            ),
          SubscriptionStatus.lapsed => (
              'Vencida',
              'Renove com PIX para reativar.',
              'Renovar com PIX',
              Icons.event_busy_outlined,
            ),
          null => (
              'Plano',
              'Assinatura anual · ${SubscriptionPricing.yearlyLabelBr}',
              'Assinar com PIX',
              Icons.workspace_premium_outlined,
            ),
        };
        final color = switch (status) {
          SubscriptionStatus.active => AppColors.trustHigh,
          SubscriptionStatus.trial => AppColors.trustMedium,
          SubscriptionStatus.expired ||
          SubscriptionStatus.lapsed =>
            AppColors.riskCritical,
          null => AppColors.primary,
        };

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                icon: Icons.workspace_premium_outlined,
                label: 'Plano',
                trailing: GuardianHeaderChip(
                  label: label,
                  color: color,
                  icon: pillIcon,
                ),
              ),
              const SizedBox(height: 12),
              Text(detail, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  GuardianLinkChip(
                    label: cta,
                    onPressed: () => context.go(AppRoutes.premium),
                    compact: true,
                  ),
                  if (kDebugMode)
                    GuardianLinkChip(
                      label: _resetting
                          ? 'Reiniciando…'
                          : 'Resetar trial (teste)',
                      icon: Icons.refresh_rounded,
                      compact: true,
                      onPressed: _resetting ? null : _resetTrial,
                    ),
                  if (kDebugMode)
                    GuardianLinkChip(
                      label: _resettingVerification
                          ? 'Resetando…'
                          : 'Resetar verificação (teste)',
                      icon: Icons.qr_code_2_rounded,
                      compact: true,
                      onPressed: _resettingVerification
                          ? null
                          : _resetVerification,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final verified = user.emailVerified;
    final tiles = <Widget>[
      _InfoTile(
        icon: Icons.smartphone_outlined,
        label: 'Aparelho',
        valueWidget: _LinkedDeviceValue(uid: user.uid),
      ),
      _InfoTile(
        icon: verified
            ? Icons.verified_outlined
            : Icons.mark_email_unread_outlined,
        label: 'E-mail verificado',
        value: verified ? 'Sim' : 'Não',
        valueColor: verified ? AppColors.trustHigh : AppColors.riskElevated,
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
    ];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            icon: Icons.person_outline,
            label: 'Informações da conta',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      tiles[i],
                    ],
                  ],
                );
              }
              return _PairGrid(tiles: tiles);
            },
          ),
        ],
      ),
    );
  }
}

/// Grade de dois por linha — mesma leitura do card "Respostas em segundos".
class _PairGrid extends StatelessWidget {
  const _PairGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < tiles.length
                    ? tiles[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 8));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.valueColor,
  }) : assert(value != null || valueWidget != null);

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor,
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
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return StreamBuilder<GuardianDevice?>(
      stream: DeviceRepository().watchPrimaryDevice(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Text('—', style: style);
        }
        final label = snapshot.data?.status.modelLabel.trim();
        return Text(
          label == null || label.isEmpty ? '—' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

class _AccountFootnote extends StatelessWidget {
  const _AccountFootnote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'A conta mantém o aparelho vinculado e prepara os recursos de '
            'nuvem. A proteção anti-furto funciona no próprio aparelho.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
      ],
    );
  }
}

/// Estado vazio no padrão de Dispositivos e Localizar.
class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Você ainda não entrou',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Entre ou crie uma conta para vincular este aparelho e preparar '
            'os recursos de nuvem. A proteção funciona mesmo sem login.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(AppRoutes.login),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.trustHigh,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Entrar ou criar conta',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
  return '$d/$m/${local.year}';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} às $h:$min';
}
