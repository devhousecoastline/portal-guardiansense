import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_confirm_dialog.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/account/data/account_deletion_service.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/auth/application/auth_error_messages.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_footer.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_form_card.dart';

/// Pública: exclusão da conta pelo site (link exigido pela Play).
///
/// Com sessão abre no layout do portal (menu lateral); sem sessão e após
/// excluir, tela pública como o login. Fluxo: login → o que é apagado e o que
/// fica → confirmar → `deleteAccount` → `signOut` → confirmação. Login antigo
/// (`failed-precondition`) pede para entrar de novo.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.service});

  final AccountDeletionService? service;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AccountDeletionService _service =
      widget.service ?? AccountDeletionService();

  bool _busy = false;
  bool _deleted = false;
  String? _error;

  /// Aviso acima do login (ex.: "entre de novo para confirmar").
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    await _runSignIn(() => auth.signInWithEmail(_email.text, _password.text));
  }

  Future<void> _signInWithGoogle(AuthController auth) async {
    await _runSignIn(auth.signInWithGoogle);
  }

  Future<void> _runSignIn(Future<void> Function() signIn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signIn();
      if (mounted) {
        _password.clear();
        setState(() => _notice = null);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Login com Google cancelado ou expirou.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = isAuthPopupCancelled(e)
            ? 'Login com Google cancelado.'
            : 'Não foi possível entrar.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword(AuthController auth) async {
    final mail = _email.text.trim();
    if (mail.isEmpty) {
      setState(() => _error = 'Informe o e-mail para redefinir a senha.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.sendPasswordReset(mail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se existir conta com $mail, enviamos um link para redefinir a senha.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndDelete(AuthController auth) async {
    final confirmed = await showGuardianConfirmDialog(
      context,
      title: 'Excluir a conta definitivamente?',
      message: 'A conta e todos os dados dela na nuvem serão apagados agora. '
          'Não dá para desfazer.',
      confirmLabel: 'Excluir conta',
      icon: Icons.delete_forever_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.deleteAccount();
      if (mounted) setState(() => _deleted = true);
      try {
        await auth.signOut();
      } catch (_) {
        // A conta já não existe; a sessão local cai sozinha.
      }
    } on AccountDeletionException catch (e) {
      await _handleFailure(auth, e.failure);
    } catch (_) {
      await _handleFailure(auth, AccountDeletionFailure.unknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleFailure(
    AuthController auth,
    AccountDeletionFailure failure,
  ) async {
    switch (failure) {
      case AccountDeletionFailure.requiresRecentLogin:
        await _signOutAndAskLogin(
          auth,
          'Por segurança, entre de novo para confirmar a exclusão.',
        );
      case AccountDeletionFailure.unauthenticated:
        await _signOutAndAskLogin(
          auth,
          'Sua sessão expirou. Entre de novo para continuar.',
        );
      case AccountDeletionFailure.network:
        if (mounted) {
          setState(() {
            _error = 'Sem conexão. Verifique a internet e tente de novo.';
          });
        }
      case AccountDeletionFailure.unknown:
        if (mounted) {
          setState(() {
            _error = 'Não foi possível excluir a conta agora. '
                'Tente de novo em instantes.';
          });
        }
    }
  }

  Future<void> _signOutAndAskLogin(AuthController auth, String notice) async {
    final mail = auth.user?.email?.trim();
    if (mail != null && mail.isNotEmpty) _email.text = mail;
    _password.clear();
    if (mounted) setState(() => _notice = notice);
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;

        if (!_deleted && auth.isReady && user != null) {
          return GuardianScaffold(
            title: 'Excluir conta',
            subtitle: 'O que é apagado, o que fica guardado e como confirmar',
            child: DeleteAccountSummary(
              email: user.email,
              busy: _busy,
              error: _error,
              onDelete: () => _confirmAndDelete(auth),
              onCancel: () => context.go(AppRoutes.account),
            ),
          );
        }

        final Widget content;
        if (_deleted) {
          content = const DeleteAccountDoneCard();
        } else if (!auth.isReady) {
          content = const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          content = _SignInStep(
            notice: _notice,
            form: LoginFormCard(
              formKey: _formKey,
              email: _email,
              password: _password,
              creating: false,
              busy: _busy,
              error: _error,
              title: 'Entre para excluir',
              subtitle: 'Use a mesma conta do app (Google ou e-mail e senha).',
              onSubmit: () => _signInWithEmail(auth),
              onGoogleSignIn: () => _signInWithGoogle(auth),
              onToggleMode: null,
              onForgotPassword: () => _forgotPassword(auth),
            ),
          );
        }

        return _PublicShell(child: content);
      },
    );
  }
}

/// Sem sessão: mesmo idioma das telas públicas (login, QR de vínculo).
class _PublicShell extends StatelessWidget {
  const _PublicShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthPageShell(
      stickyFooter: false,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GuardianLogo(size: 80),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Excluir conta',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.privacyPublic),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                    ),
                    child: const Text('Política de Privacidade'),
                  ),
                ),
                const AuthFooter(includeHorizontalPadding: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInStep extends StatelessWidget {
  const _SignInStep({required this.form, this.notice});

  final Widget form;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Para excluir sua conta do Guardian Sense e os dados dela na nuvem, '
          'entre primeiro. Antes de apagar, mostramos o que será removido.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 16),
          SectionCard(
            accentColor: AppColors.riskElevated,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(notice!, style: theme.textTheme.bodyMedium),
          ),
        ],
        const SizedBox(height: 20),
        form,
      ],
    );
  }
}

/// Com sessão: cards no padrão de Minha conta, lado a lado em tela larga.
class DeleteAccountSummary extends StatelessWidget {
  const DeleteAccountSummary({
    super.key,
    required this.email,
    required this.busy,
    required this.error,
    required this.onDelete,
    required this.onCancel,
  });

  final String? email;
  final bool busy;
  final String? error;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  static const _deleted = [
    'A conta de acesso (login Google ou e-mail e senha)',
    'Aparelhos vinculados e o estado da proteção na nuvem',
    'Trilha de localização e eventos de proteção',
    'Comandos remotos enviados pelo portal',
    'Plano e assinatura vinculados à conta',
  ];

  static const _kept = [
    'Um código irreversível (hash) do e-mail, sem o e-mail em si, para o '
        'período de teste não recomeçar se você criar outra conta',
    'Registros de pagamento PIX, sem vínculo com a conta, por obrigação '
        'fiscal',
    'Os dados no próprio celular: a proteção local do Guardian Sense '
        'continua funcionando sem conta',
  ];

  @override
  Widget build(BuildContext context) {
    const deletedCard = _ListCard(
      icon: Icons.delete_outline_rounded,
      title: 'O que é apagado',
      color: _ListColor.critical,
      mark: '✕',
      items: _deleted,
    );
    const keptCard = _ListCard(
      icon: Icons.inventory_2_outlined,
      title: 'O que fica guardado',
      color: _ListColor.kept,
      mark: '✓',
      items: _kept,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [deletedCard, SizedBox(height: 16), keptCard],
              );
            }
            return const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: deletedCard),
                  SizedBox(width: 16),
                  Expanded(child: keptCard),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ConfirmCard(
          email: email,
          busy: busy,
          error: error,
          onDelete: onDelete,
          onCancel: onCancel,
        ),
      ],
    );
  }
}

enum _ListColor { critical, kept }

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.mark,
    required this.items,
  });

  final IconData icon;
  final String title;
  final _ListColor color;
  final String mark;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (color) {
      _ListColor.critical => AppColors.riskCritical,
      _ListColor.kept => AppColors.trustHigh,
    };

    return SectionCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(icon: icon, label: title),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$mark ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.email,
    required this.busy,
    required this.error,
    required this.onDelete,
    required this.onCancel,
  });

  final String? email;
  final bool busy;
  final String? error;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mail = email?.trim();

    return SectionCard(
      accentColor: AppColors.riskCritical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            icon: Icons.warning_amber_rounded,
            label: 'Confirmar exclusão',
          ),
          const SizedBox(height: 12),
          Text(
            mail == null || mail.isEmpty
                ? 'A exclusão vale para a conta conectada a este portal. '
                    'É imediata e não dá para desfazer.'
                : 'A exclusão vale para a conta $mail. '
                    'É imediata e não dá para desfazer.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: AppColors.riskCritical)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GuardianPillButton(
                label: 'Excluir minha conta',
                icon: Icons.delete_forever_outlined,
                iconLeading: true,
                danger: true,
                busy: busy,
                onPressed: busy ? null : onDelete,
              ),
              GuardianPillButton(
                label: 'Cancelar',
                icon: Icons.arrow_back_rounded,
                iconLeading: true,
                neutral: true,
                onPressed: busy ? null : onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mesmo título de card de Minha conta.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class DeleteAccountDoneCard extends StatelessWidget {
  const DeleteAccountDoneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      accentColor: AppColors.trustHigh,
      child: Column(
        children: [
          Text(
            '✓',
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.trustHigh,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conta excluída',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua conta e os dados dela na nuvem foram apagados. No celular, '
            'a proteção local do Guardian Sense continua funcionando sem conta.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          GuardianPillButton(
            label: 'Ir para o início',
            icon: Icons.arrow_forward_rounded,
            fullWidth: true,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
