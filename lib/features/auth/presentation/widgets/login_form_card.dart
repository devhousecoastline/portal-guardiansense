import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/google_g_mark.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.trustHigh.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.trustHigh.withValues(alpha: 0.28),
              AppColors.divider.withValues(alpha: 0.9),
              AppColors.trustHigh.withValues(alpha: 0.12),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(1.1),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                creating ? 'Nova conta' : AppConstants.loginCardTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                creating
                    ? 'Preencha os dados para começar.'
                    : AppConstants.loginCardSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration:
                          loginFieldDecoration.copyWith(labelText: 'E-mail'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o e-mail'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration:
                          loginFieldDecoration.copyWith(labelText: 'Senha'),
                      validator: (v) => v == null || v.length < 6
                          ? 'Mínimo de 6 caracteres'
                          : null,
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
              const SizedBox(height: 24),
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
                leading: const GoogleGMark(size: 16),
                iconLeading: true,
                neutral: true,
                compact: true,
                fullWidth: true,
                busy: busy,
                onPressed: busy ? null : onGoogleSignIn,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : onToggleMode,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.trustHigh,
                ),
                child: Text(
                  creating
                      ? 'Já possui conta? Entrar'
                      : 'Ainda não possui conta? Criar conta',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
