import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
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
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool creating;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            creating ? 'Nova conta' : AppConstants.portalTitle,
            style: Theme.of(context).textTheme.headlineMedium,
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
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: const TextStyle(color: AppColors.riskCritical)),
          ],
          const SizedBox(height: 24),
          GuardianPillButton(
            label: creating ? 'Criar conta' : 'Entrar',
            icon: Icons.arrow_forward_rounded,
            fullWidth: true,
            busy: busy,
            onPressed: busy ? null : onSubmit,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(
              creating ? 'Já tenho conta — entrar' : 'Primeiro acesso — criar conta',
            ),
          ),
        ],
      ),
    );
  }
}
