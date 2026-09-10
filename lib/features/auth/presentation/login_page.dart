import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_footer.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_surface_card.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_brand_panel.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_form_card.dart';
import 'package:guardian_portal/features/info/presentation/privacy_consent_scope.dart';

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

  Widget _formCard(
    AuthController auth, {
    required bool busy,
    bool fillHeight = false,
    bool embedded = false,
  }) {
    return LoginFormCard(
      formKey: _formKey,
      email: _email,
      password: _password,
      creating: _creating,
      busy: busy,
      error: _error,
      fillHeight: fillHeight,
      embedded: embedded,
      onSubmit: () => _submit(auth),
      onGoogleSignIn: () => _signInWithGoogle(auth),
      onToggleMode: () => _setCreating(!_creating),
      onForgotPassword: () => _forgotPassword(auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final consent = PrivacyConsentScope.of(context);
    // Após o login, segura o busy até o Firestore do aceite responder —
    // evita flash do formulário antes do redirect.
    final waitingConsent = auth.user != null && !consent.isReady;
    final busy = _busy || waitingConsent;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return AuthPageShell(
      stickyFooter: wide,
      body: wide
          ? _DesktopLoginBody(
              // Remonta ao trocar modo/erro para re-medir a altura do card.
              key: ValueKey('$_creating|${_error ?? ''}'),
              formBuilder: (fill) => _formCard(
                auth,
                busy: busy,
                fillHeight: fill,
                embedded: true,
              ),
            )
          : _MobileLoginBody(form: _formCard(auth, busy: busy)),
    );
  }
}

class _DesktopLoginBody extends StatefulWidget {
  const _DesktopLoginBody({super.key, required this.formBuilder});

  final Widget Function(bool fillHeight) formBuilder;

  @override
  State<_DesktopLoginBody> createState() => _DesktopLoginBodyState();
}

class _DesktopLoginBodyState extends State<_DesktopLoginBody> {
  final _brandKey = GlobalKey();
  final _formKey = GlobalKey();
  double? _syncedHeight;

  void _syncHeights() {
    final brandH = _brandKey.currentContext?.size?.height;
    final formH = _formKey.currentContext?.size?.height;
    if (brandH == null || formH == null) return;
    final next = brandH > formH ? brandH : formH;
    if (_syncedHeight != null && (next - _syncedHeight!).abs() < 1) return;
    setState(() => _syncedHeight = next);
  }

  @override
  Widget build(BuildContext context) {
    final synced = _syncedHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncHeights();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final logoSize = (constraints.maxHeight * 0.14).clamp(96.0, 128.0);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: AuthSurfaceCard(
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        key: _brandKey,
                        height: synced,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
                          child: LoginBrandPanel(
                            logoSize: logoSize,
                            embedded: true,
                            fillHeight: synced != null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: synced,
                      child: VerticalDivider(
                        width: 20,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.divider.withValues(alpha: 0.28),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        key: _formKey,
                        height: synced,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 22, 22),
                          child: widget.formBuilder(synced != null),
                        ),
                      ),
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
}

class _MobileLoginBody extends StatelessWidget {
  const _MobileLoginBody({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final short = size.height < 760;
    final logoSize = short ? 56.0 : 72.0;
    // Margem simétrica — evita o card “colado” numa lateral no Chrome mobile.
    final hPad = (size.width * 0.06).clamp(20.0, 28.0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, short ? 8 : 20, hPad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginBrandPanel(
            logoSize: logoSize,
            centered: true,
            showHighlights: !short,
          ),
          SizedBox(height: short ? 16 : 24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: form,
            ),
          ),
          const SizedBox(height: 8),
          const AuthFooter(includeHorizontalPadding: false),
        ],
      ),
    );
  }
}
