import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_form_card.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_institutional_panel.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/login_watermark.dart';

enum _LoginLayout { mobile, tablet, desktop }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _error;

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
        'popup-closed-by-user' => 'Login com Google cancelado.',
        _ => e.message ?? 'Não foi possível entrar.',
      };

  Future<void> _signInWithGoogle(AuthController auth) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _LoginLayout _layoutFor(double width) {
    if (width < 720) return _LoginLayout.mobile;
    if (width < 1000) return _LoginLayout.tablet;
    return _LoginLayout.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 0.95,
                colors: [
                  AppColors.loginBackgroundCenter,
                  AppColors.loginBackgroundMid,
                  AppColors.loginBackgroundEdge,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return LoginWatermark(size: constraints.maxWidth * 0.55);
            },
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _layoutFor(constraints.maxWidth);
                final isWide = layout != _LoginLayout.mobile;
                final horizontalPadding = isWide ? 48.0 : 24.0;
                final columnGap = layout == _LoginLayout.desktop ? 80.0 : 40.0;
                final contentMaxWidth =
                    isWide ? AppConstants.loginMaxWidth : 420.0;
                final body = isWide
                    ? _WideLoginBody(
                        layout: layout,
                        columnGap: columnGap,
                        compact: constraints.maxHeight < 820,
                        formKey: _formKey,
                        email: _email,
                        password: _password,
                        creating: _creating,
                        busy: _busy,
                        error: _error,
                        onSubmit: () => _submit(auth),
                        onGoogleSignIn: () => _signInWithGoogle(auth),
                        onToggleMode: () => setState(() {
                          _creating = !_creating;
                          _error = null;
                        }),
                      )
                    : _MobileLoginBody(
                        formKey: _formKey,
                        email: _email,
                        password: _password,
                        creating: _creating,
                        busy: _busy,
                        error: _error,
                        onSubmit: () => _submit(auth),
                        onGoogleSignIn: () => _signInWithGoogle(auth),
                        onToggleMode: () => setState(() {
                          _creating = !_creating;
                          _error = null;
                        }),
                      );

                final content = ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isWide ? 40 : 32,
                    ),
                    child: body,
                  ),
                );

                // minHeight centraliza quando cabe; scroll só quando o conteúdo passa da viewport.
                // maxWidth evita overflow horizontal do Row dentro do scroll.
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: content,
                          ),
                        ),
                      ),
                    ),
                    const _LoginFooter(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WideLoginBody extends StatelessWidget {
  const _WideLoginBody({
    required this.layout,
    required this.columnGap,
    required this.compact,
    required this.formKey,
    required this.email,
    required this.password,
    required this.creating,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onToggleMode,
  });

  final _LoginLayout layout;
  final double columnGap;
  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool creating;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 72.0 : 88.0;
    final brandGap = compact ? 32.0 : (layout == _LoginLayout.desktop ? 48.0 : 36.0);
    final useColumn = layout == _LoginLayout.tablet && compact;

    final institutional = LoginInstitutionalPanel(creating: creating);
    final form = LoginFormCard(
      formKey: formKey,
      email: email,
      password: password,
      creating: creating,
      busy: busy,
      error: error,
      onSubmit: onSubmit,
      onGoogleSignIn: onGoogleSignIn,
      onToggleMode: onToggleMode,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LoginBrand(logoSize: logoSize, compact: compact),
        SizedBox(height: brandGap),
        if (useColumn) ...[
          institutional,
          const SizedBox(height: 28),
          form,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: institutional),
              SizedBox(width: columnGap),
              Expanded(flex: 4, child: form),
            ],
          ),
      ],
    );
  }
}

class _MobileLoginBody extends StatelessWidget {
  const _MobileLoginBody({
    required this.formKey,
    required this.email,
    required this.password,
    required this.creating,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool creating;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LoginBrand(logoSize: 80),
        const SizedBox(height: 32),
        LoginInstitutionalPanel(creating: creating),
        const SizedBox(height: 28),
        LoginFormCard(
          formKey: formKey,
          email: email,
          password: password,
          creating: creating,
          busy: busy,
          error: error,
          onSubmit: onSubmit,
          onGoogleSignIn: onGoogleSignIn,
          onToggleMode: onToggleMode,
        ),
      ],
    );
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand({required this.logoSize, this.compact = false});

  final double logoSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GuardianLogo(size: logoSize),
        SizedBox(height: compact ? 20 : 32),
        Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineLarge),
        SizedBox(height: compact ? 8 : 12),
        Text(
          AppConstants.portalTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.footerTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMuted.withValues(alpha: 0.65),
              ),
        ),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: AppColors.textMuted.withValues(alpha: 0.7),
        );

    final copyright = muted?.copyWith(
      fontSize: 11,
      color: AppColors.textMuted.withValues(alpha: 0.5),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Text(AppConstants.appVersion, style: muted),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} ${AppConstants.copyrightHolder}. '
            'Todos os direitos reservados.',
            style: copyright,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
