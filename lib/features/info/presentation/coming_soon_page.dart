import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_footer.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_page_shell.dart';

/// Landing pública pré-lançamento — home do domínio sem expor o login.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final short = MediaQuery.sizeOf(context).height < 700;

    return AuthPageShell(
      stickyFooter: wide,
      body: wide
          ? _WideBody(short: short)
          : _NarrowBody(short: short),
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({required this.short});

  final bool short;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _ComingSoonContent(logoSize: short ? 120.0 : 160.0),
        ),
      ),
    );
  }
}

class _NarrowBody extends StatelessWidget {
  const _NarrowBody({required this.short});

  final bool short;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, short ? 12 : 28, 24, 12),
      child: Column(
        children: [
          _ComingSoonContent(logoSize: short ? 88.0 : 112.0),
          const SizedBox(height: 8),
          const AuthFooter(includeHorizontalPadding: false),
        ],
      ),
    );
  }
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent({required this.logoSize});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GuardianLogo(size: logoSize, breathe: true),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Em desenvolvimento',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.trustHigh,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Estamos preparando o Guardian Sense e a Central de Proteção. '
          'Em breve, novidades por aqui.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
