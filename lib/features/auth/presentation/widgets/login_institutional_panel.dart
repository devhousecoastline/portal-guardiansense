import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';

class LoginInstitutionalPanel extends StatelessWidget {
  const LoginInstitutionalPanel({super.key, required this.creating});

  final bool creating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          creating ? 'Criar conta' : AppConstants.loginHeadline,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                height: 1.25,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          creating
              ? 'Crie sua conta para acessar o painel de proteção.'
              : AppConstants.loginDescription,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (!creating) ...[
          const SizedBox(height: 32),
          const _RuntimeBadge(),
          const SizedBox(height: 24),
          ...AppConstants.loginFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeatureRow(label: feature),
            ),
          ),
        ],
      ],
    );
  }
}

class _RuntimeBadge extends StatelessWidget {
  const _RuntimeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.trustHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.trustHigh.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.trustHigh,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Runtime protegido',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.trustHigh,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_rounded,
          size: 20,
          color: AppColors.primary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
          ),
        ),
      ],
    );
  }
}
