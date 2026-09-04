import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';

/// Selo de verificação — mesmo recuo e tipo do [DeviceOnlineChip].
class DeviceVerifiedChip extends StatelessWidget {
  const DeviceVerifiedChip({
    super.key,
    this.compact = false,
    this.verified = true,
    this.expand = false,
  });

  final bool compact;
  final bool verified;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = verified ? AppColors.trustHigh : AppColors.riskElevated;
    final label = verified
        ? (compact ? 'Verificado' : 'Ativo e verificado')
        : 'Não verificado';

    return GuardianHeaderChip(
      label: label,
      color: accent,
      icon: verified ? Icons.verified_rounded : Icons.gpp_maybe_outlined,
      expand: expand,
    );
  }
}
