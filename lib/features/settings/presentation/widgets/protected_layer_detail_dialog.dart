import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_confirm_dialog.dart';
import 'package:guardian_portal/core/widgets/premium_badge.dart';
import 'package:guardian_portal/features/containment/data/device_commands_repository.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

Future<void> showProtectedLayerDetailDialog(
  BuildContext context, {
  required ProtectedLayerSummary layer,
  required String uid,
  required String deviceId,
  required bool muted,
  bool extraProtectEnabled = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ProtectedLayerDetailDialog(
      layer: layer,
      uid: uid,
      deviceId: deviceId,
      muted: muted,
      extraProtectEnabled: extraProtectEnabled,
    ),
  );
}

class _ProtectedLayerDetailDialog extends StatefulWidget {
  const _ProtectedLayerDetailDialog({
    required this.layer,
    required this.uid,
    required this.deviceId,
    required this.muted,
    required this.extraProtectEnabled,
  });

  final ProtectedLayerSummary layer;
  final String uid;
  final String deviceId;
  final bool muted;
  final bool extraProtectEnabled;

  @override
  State<_ProtectedLayerDetailDialog> createState() =>
      _ProtectedLayerDetailDialogState();
}

class _ProtectedLayerDetailDialogState extends State<_ProtectedLayerDetailDialog> {
  final _repository = DeviceCommandsRepository();
  String? _submittingPackage;

  Future<void> _protectApp(ProtectedLayerAppSummary app) async {
    if (_isPremiumLocked(app)) return;
    if (widget.muted || !app.canProtectRemotely || _submittingPackage != null) {
      if (widget.muted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aparelho offline. Conecte o celular para enviar comandos.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirmed = await showGuardianConfirmDialog(
      context,
      title: 'Proteger ${app.label} remotamente?',
      message:
          'O aparelho adicionará o app à lista de proteção quando receber o comando.',
      confirmLabel: 'Proteger app',
      icon: Icons.verified_user,
      accentColor: AppColors.trustHigh,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submittingPackage = app.packageName);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _repository.requestProtectApp(
        uid: widget.uid,
        deviceId: widget.deviceId,
        requestedBy: user.uid,
        packageName: app.packageName!,
        label: app.label,
        sectionId: widget.layer.sectionId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comando enviado. ${app.label} será protegido quando o celular sincronizar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DeviceCommandAlreadyPendingException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DeviceCommandRateLimitException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível enviar o comando: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingPackage = null);
    }
  }

  /// Free: 1 app protegido por camada. Se já há protegido, o resto é Premium.
  /// Se nenhum está protegido, só o 1º "Proteger" é free.
  bool _isPremiumLocked(ProtectedLayerAppSummary app) {
    if (!app.canProtectRemotely || widget.extraProtectEnabled) return false;
    return !_isFreeProtectSlot(widget.layer, app);
  }

  static bool _isFreeProtectSlot(
    ProtectedLayerSummary layer,
    ProtectedLayerAppSummary app,
  ) {
    final alreadyProtected = layer.apps.any((a) => a.protected);
    if (alreadyProtected) return false;

    for (final candidate in layer.apps) {
      if (!candidate.canProtectRemotely) continue;
      return candidate.packageName == app.packageName;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.42;
    final hasRemoteActions =
        widget.layer.apps.any((app) => app.canProtectRemotely);

    return Dialog(
      insetPadding:  EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:  BorderSide(color: AppColors.divider),
      ),
      child: ConstrainedBox(
        constraints:  BoxConstraints(maxWidth: 440),
        child: Padding(
          padding:  EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogAccentIcon(
                    child: Icon(widget.layer.icon, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.layer.displayTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                           SizedBox(height: 4),
                          Text(
                            _headerSubtitle(widget.layer),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:  BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon:  Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (widget.layer.apps.isEmpty)
                const _AppsUnavailableHint()
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.layer.apps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final app = widget.layer.apps[index];
                      final premiumLocked = _isPremiumLocked(app);
                      return _AppRow(
                        app: app,
                        muted: widget.muted,
                        submitting: _submittingPackage == app.packageName,
                        premiumLocked: premiumLocked,
                        onProtect: app.canProtectRemotely && !premiumLocked
                            ? () => _protectApp(app)
                            : null,
                      );
                    },
                  ),
                ),
               SizedBox(height: 16),
              Text(
                hasRemoteActions
                    ? 'Apps fora da proteção podem ser reforçados remotamente. '
                        'Outros ajustes ficam no app Guardian Sense.'
                    : 'Para alterar a proteção, abra Camadas protegidas no app Guardian Sense.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _headerSubtitle(ProtectedLayerSummary layer) {
  if (layer.unprotectedCount == 0) {
    return layer.protectedLabel;
  }
  return '${layer.protectedLabel} · ${layer.unprotectedLabel}';
}

class _DialogAccentIcon extends StatelessWidget {
  const _DialogAccentIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.muted,
    required this.submitting,
    required this.onProtect,
    this.premiumLocked = false,
  });

  final ProtectedLayerAppSummary app;
  final bool muted;
  final bool submitting;
  final VoidCallback? onProtect;
  final bool premiumLocked;

  @override
  Widget build(BuildContext context) {
    final protected = app.protected;
    final accent = muted
        ? AppColors.textMuted
        : (protected ? AppColors.trustHigh : AppColors.trustMedium);
    final canProtect = onProtect != null && !muted;
    final showProtectSlot = canProtect || (premiumLocked && !muted && !protected);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              protected ? Icons.verified_user : Icons.warning_amber_rounded,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    protected ? 'Protegido' : 'Fora da proteção',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            if (showProtectSlot) ...[
              const SizedBox(width: 8),
              if (submitting)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (premiumLocked)
                Tooltip(
                  message: 'Disponível no plano Premium ativo',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.trustHigh,
                          disabledForegroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Proteger'),
                      ),
                      const SizedBox(width: 6),
                      const PremiumBadge(compact: true),
                    ],
                  ),
                )
              else
                TextButton(
                  onPressed: onProtect,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.trustHigh,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Proteger'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppsUnavailableHint extends StatelessWidget {
  const _AppsUnavailableHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(Icons.sync, size: 18, color: AppColors.textMuted),
           SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lista de apps ainda não sincronizada. Abra o Guardian Sense no celular para atualizar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
