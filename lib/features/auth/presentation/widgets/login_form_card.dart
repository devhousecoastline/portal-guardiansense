import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/google_g_mark.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_surface_card.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.email,
    required this.password,
    required this.creating,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onToggleMode,
    required this.onForgotPassword,
    this.fillHeight = false,
    this.embedded = false,
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
  final VoidCallback onForgotPassword;

  /// Desktop: preenche a altura igualada ao painel da marca.
  final bool fillHeight;

  /// Dentro do card unificado (sem chrome próprio).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(
          creating ? 'Nova conta' : AppConstants.loginCardTitle,
          textAlign: narrow ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
        ),
        if (!creating) ...[
          const SizedBox(height: 8),
          Text(
            AppConstants.loginCardSubtitle,
            textAlign: narrow ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ] else if (!narrow) ...[
          const SizedBox(height: 8),
          Text(
            'Preencha os dados para começar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
          SizedBox(height: narrow ? 16 : 20),
          Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: loginFieldDecoration.copyWith(labelText: 'E-mail'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: loginFieldDecoration.copyWith(labelText: 'Senha'),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Mínimo de 6 caracteres' : null,
              ),
              if (!creating) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: busy ? null : onForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Esqueci a senha'),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!, style: TextStyle(color: AppColors.riskCritical)),
        ],
        const SizedBox(height: 18),
        GuardianPillButton(
          label: creating ? 'Criar conta' : 'Entrar',
          icon: Icons.arrow_forward_rounded,
          fullWidth: true,
          busy: busy,
          onPressed: busy ? null : onSubmit,
        ),
        const SizedBox(height: 10),
        GuardianPillButton(
          label: 'Continuar com Google',
          leading: const GoogleGMark(size: 19),
          iconLeading: true,
          neutral: true,
          fullWidth: true,
          busy: busy,
          onPressed: busy ? null : onGoogleSignIn,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onToggleMode,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
          ),
          child: Text(
            creating
                ? 'Já possui conta? Entrar'
                : 'Ainda não possui conta? Criar conta',
          ),
        ),
      ],
    );

    final child = fillHeight ? SizedBox.expand(child: body) : body;
    if (embedded) return child;
    return AuthSurfaceCard(child: child);
  }
}
