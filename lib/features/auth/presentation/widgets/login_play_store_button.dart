import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// CTA da ficha do app no Google Play, na tela de login.
class LoginPlayStoreButton extends StatelessWidget {
  const LoginPlayStoreButton({super.key, this.fullWidth = false});

  final bool fullWidth;

  static final _uri = Uri.parse(AppConstants.playStoreUrl);

  static Future<void> open() =>
      launchUrl(_uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppConstants.loginStoreTooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: GuardianPillButton(
        label: AppConstants.loginStoreCta,
        icon: Icons.android,
        iconLeading: true,
        fullWidth: fullWidth,
        onPressed: open,
      ),
    );
  }
}
