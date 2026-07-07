import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
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

  void _setCreating(bool value) {
    setState(() {
      _creating = value;
      _error = null;
    });
    final uri = value ? '${AppRoutes.login}?criar=1' : AppRoutes.login;
    context.go(uri);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < 720;

    return AuthPageShell(
      appBar: const AuthAppBar.login(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 48,
              vertical: compact ? 28 : 48,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: LoginFormCard(
                    formKey: _formKey,
                    email: _email,
                    password: _password,
                    creating: _creating,
                    busy: _busy,
                    error: _error,
                    onSubmit: () => _submit(auth),
                    onGoogleSignIn: () => _signInWithGoogle(auth),
                    onToggleMode: () => _setCreating(!_creating),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
