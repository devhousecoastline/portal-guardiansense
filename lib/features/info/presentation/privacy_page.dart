import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/info/domain/privacy_policy.dart';

/// Política de Privacidade — mesmas informações do app.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, this.standalone = false});

  /// Sem drawer — leitura a partir do aceite pós-login.
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final body = const PrivacyPolicyView();

    if (standalone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(PrivacyPolicy.title),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: body,
            ),
          ),
        ),
      );
    }

    return GuardianScaffold(
      title: PrivacyPolicy.title,
      subtitle: 'O que o Guardian Sense usa e o que pode ir ao portal',
      child: body,
    );
  }
}

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < PrivacyPolicy.sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _PrivacySectionCard(section: PrivacyPolicy.sections[i]),
        ],
      ],
    );
  }
}

class _PrivacySectionCard extends StatelessWidget {
  const _PrivacySectionCard({required this.section});

  final PrivacySection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title != null) ...[
            Text(
              section.title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (section.body.isNotEmpty)
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✓ ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.trustHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
