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
/// Login → o que é apagado e o que fica → confirmar → `deleteAccount` →
/// `signOut` → confirmação. Login antigo (`failed-precondition`) pede para
/// entrar de novo.
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

  Future<void> _useAnotherAccount(AuthController auth) async {
    setState(() {
      _error = null;
      _notice = null;
    });
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AuthPageShell(
      stickyFooter: false,
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final user = auth.user;
          final Widget content;
          if (_deleted) {
            content = const _DeletedCard();
          } else if (!auth.isReady) {
            content = const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (user == null) {
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
          } else {
            content = _ExplanationStep(
              email: user.email,
              busy: _busy,
              error: _error,
              onDelete: () => _confirmAndDelete(auth),
              onCancel: () => context.go(AppRoutes.dashboard),
              onUseAnotherAccount: () => _useAnotherAccount(auth),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Header(),
                    const SizedBox(height: 24),
                    content,
                    const SizedBox(height: 20),
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
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
      ],
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

class _ExplanationStep extends StatelessWidget {
  const _ExplanationStep({
    required this.email,
    required this.busy,
    required this.error,
    required this.onDelete,
    required this.onCancel,
    required this.onUseAnotherAccount,
  });

  final String? email;
  final bool busy;
  final String? error;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback onUseAnotherAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mail = email?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mail == null || mail.isEmpty
              ? 'Você está na conta conectada a este portal.'
              : 'Conta: $mail',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const _ListCard(
          icon: Icons.delete_outline_rounded,
          title: 'O que é apagado',
          accent: _ListAccent.critical,
          items: [
            'A conta de acesso (login Google ou e-mail e senha)',
            'Aparelhos vinculados e o estado da proteção na nuvem',
            'Trilha de localização e eventos de proteção',
            'Comandos remotos enviados pelo portal',
            'Plano e assinatura vinculados à conta',
          ],
        ),
        const SizedBox(height: 12),
        const _ListCard(
          icon: Icons.inventory_2_outlined,
          title: 'O que fica',
          accent: _ListAccent.neutral,
          items: [
            'Um código irreversível (hash) do e-mail, sem o e-mail em si, '
                'para o período de teste não recomeçar se você criar outra '
                'conta',
            'Registros de pagamento PIX, sem vínculo com a conta, por '
                'obrigação fiscal',
            'Os dados no próprio celular: a proteção local do Guardian Sense '
                'continua funcionando sem conta',
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          accentColor: AppColors.riskCritical,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: AppColors.riskCritical,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A exclusão é imediata e não dá para desfazer.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.riskCritical),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : onDelete,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.riskCritical,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const StadiumBorder(),
          ),
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: const Text(
            'Excluir minha conta',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        GuardianPillButton(
          label: 'Cancelar',
          icon: Icons.arrow_back_rounded,
          iconLeading: true,
          neutral: true,
          fullWidth: true,
          onPressed: busy ? null : onCancel,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: busy ? null : onUseAnotherAccount,
          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          child: const Text('Usar outra conta'),
        ),
      ],
    );
  }
}

enum _ListAccent { critical, neutral }

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.items,
  });

  final IconData icon;
  final String title;
  final _ListAccent accent;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (accent) {
      _ListAccent.critical => AppColors.riskCritical,
      _ListAccent.neutral => AppColors.textMuted,
    };

    return SectionCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
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

class _DeletedCard extends StatelessWidget {
  const _DeletedCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      accentColor: AppColors.trustHigh,
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 40,
            color: AppColors.trustHigh,
          ),
          const SizedBox(height: 12),
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
