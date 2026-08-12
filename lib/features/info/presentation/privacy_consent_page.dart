import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/info/domain/privacy_policy.dart';
import 'package:guardian_portal/features/info/presentation/privacy_consent_scope.dart';
import 'package:guardian_portal/features/info/presentation/privacy_page.dart';

/// Aceite bloqueante após o login — uma vez por versão da política.
class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({super.key});

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    if (!_accepted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PrivacyConsentScope.of(context).acceptCurrentPolicy();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível registrar o aceite. Tente de novo.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openFullPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPage(standalone: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consent = PrivacyConsentScope.of(context);

    return AuthPageShell(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: !consent.isReady
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _ConsentCard(
                    accepted: _accepted,
                    busy: _busy,
                    error: _error,
                    onAcceptedChanged: (value) {
                      setState(() => _accepted = value);
                    },
                    onReadPolicy: _openFullPolicy,
                    onConfirm: _confirm,
                    onSignOut: () => AuthScope.of(context).signOut(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.accepted,
    required this.busy,
    required this.error,
    required this.onAcceptedChanged,
    required this.onReadPolicy,
    required this.onConfirm,
    required this.onSignOut,
  });

  final bool accepted;
  final bool busy;
  final String? error;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onReadPolicy;
  final VoidCallback onConfirm;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 40,
                color: AppColors.trustHigh,
              ),
              const SizedBox(height: 12),
              Text(
                'Privacidade e termos',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Antes de continuar, precisamos do seu aceite. O Guardian Sense '
                'processa sensores no aparelho e, com conta, pode sincronizar '
                'eventos e localização de emergência com o portal.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const _Bullet('Sensores e tela ficam no aparelho'),
              const _Bullet('Portal só com conta (eventos / emergência)'),
              const _Bullet('Sem áudio e sem ler mensagens'),
              const _Bullet(
                'Não cobre engenharia reversa ou ataques fora do app',
              ),
              const SizedBox(height: 8),
              Text(
                'O aceite fica na sua conta e vale neste portal até a política mudar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              GuardianPillButton(
                label:
                    'Ler política completa (v${PrivacyPolicy.version})',
                icon: Icons.menu_book_outlined,
                iconLeading: true,
                fullWidth: true,
                neutral: true,
                onPressed: busy ? null : onReadPolicy,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: busy ? null : () => onAcceptedChanged(!accepted),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: accepted,
                        activeColor: AppColors.trustHigh,
                        onChanged: busy
                            ? null
                            : (value) => onAcceptedChanged(value ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Li e aceito a Política de Privacidade '
                            '(versão ${PrivacyPolicy.version}).',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.riskCritical,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              GuardianPillButton(
                label: 'Continuar',
                icon: Icons.arrow_forward_rounded,
                fullWidth: true,
                busy: busy,
                onPressed: accepted && !busy ? onConfirm : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: busy ? null : onSignOut,
          child: Text(
            'Sair da conta',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✓ ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.trustHigh,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
