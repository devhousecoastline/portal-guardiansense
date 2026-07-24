import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_brand_panel.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_form_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialCreating = false});

  final bool initialCreating;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _creating;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _creating = widget.initialCreating;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_creating) {
        await auth.registerWithEmail(_email.text, _password.text);
      } else {
        await auth.signInWithEmail(_email.text, _password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'E-mail ou senha incorretos. Se você entrou pelo Google no app, '
          'use «Continuar com Google».',
        'email-already-in-use' =>
          'Este e-mail já está cadastrado. Se você usa o app com Google, '
          'clique em «Continuar com Google».',
        'weak-password' => 'Senha muito fraca (mínimo 6 caracteres).',
        'invalid-email' => 'E-mail inválido.',
        'popup-closed-by-user' || 'cancelled-popup-request' =>
          'Login com Google cancelado.',
        'timeout' => 'Tempo esgotado. Tente novamente.',
        _ => e.message ?? 'Não foi possível entrar.',
      };

  bool _isPopupCancelled(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('popup-closed-by-user') ||
        text.contains('cancelled-popup-request') ||
        text.contains('user cancelled') ||
        text.contains('user canceled');
  }

  Future<void> _signInWithGoogle(AuthController auth) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(e));
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Login com Google cancelado ou expirou.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _isPopupCancelled(e)
            ? 'Login com Google cancelado.'
            : 'Não foi possível entrar com Google.';
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
      _resetFormToInitial();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se existir conta com $mail, enviamos um link para redefinir a senha.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetFormToInitial() {
    _email.clear();
    _password.clear();
    _formKey.currentState?.reset();
    setState(() {
      _creating = false;
      _error = null;
      _busy = false;
    });
    context.go(AppRoutes.login);
  }

  void _setCreating(bool value) {
    setState(() {
      _creating = value;
      _error = null;
    });
    final uri = value ? '${AppRoutes.login}?criar=1' : AppRoutes.login;
    context.go(uri);
  }

  Widget _formCard(AuthController auth) {
    return LoginFormCard(
      formKey: _formKey,
      email: _email,
      password: _password,
      creating: _creating,
      busy: _busy,
      error: _error,
      onSubmit: () => _submit(auth),
      onGoogleSignIn: () => _signInWithGoogle(auth),
      onToggleMode: () => _setCreating(!_creating),
      onForgotPassword: () => _forgotPassword(auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return AuthPageShell(
      body: wide
          ? _DesktopLoginBody(form: _formCard(auth))
          : _MobileLoginBody(form: _formCard(auth)),
    );
  }
}

class _DesktopLoginBody extends StatelessWidget {
  const _DesktopLoginBody({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Escudo um pouco menor = peso mais próximo do card.
        final logoSize = (constraints.maxHeight * 0.32).clamp(190.0, 228.0);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: LoginBrandPanel(logoSize: logoSize),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: form,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileLoginBody extends StatelessWidget {
  const _MobileLoginBody({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GuardianLogo(size: 72, breathe: true),
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.portalTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: form,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
