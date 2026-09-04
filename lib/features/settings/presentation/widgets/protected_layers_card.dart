import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_confirm_dialog.dart';
import 'package:guardian_portal/core/widgets/live_status_tile.dart';
import 'package:guardian_portal/core/widgets/premium_badge.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/containment/data/device_commands_repository.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';
import 'package:guardian_portal/features/settings/presentation/widgets/protected_layer_detail_dialog.dart';

class ProtectedLayersCard extends StatefulWidget {
  const ProtectedLayersCard({
    super.key,
    required this.uid,
    required this.status,
    this.protectAllEnabled = true,
    this.extraProtectEnabled = true,
  });

  final String uid;
  final DeviceStatus status;

  /// Plano Premium ativo — habilita o comando remoto em massa.
  final bool protectAllEnabled;

  /// Plano Premium ativo — habilita Proteger além do 1º app da camada.
  final bool extraProtectEnabled;

  @override
  State<ProtectedLayersCard> createState() => _ProtectedLayersCardState();
}

class _ProtectedLayersCardState extends State<ProtectedLayersCard> {
  final _repository = DeviceCommandsRepository();
  var _submittingAll = false;

  DeviceStatus get status => widget.status;

  Future<void> _protectAll(List<ProtectAppCommandTarget> targets) async {
    if (!widget.protectAllEnabled) return;
    if (_submittingAll || targets.isEmpty || !status.isOnline) {
      if (!status.isOnline && mounted) {
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

    final count = targets.length;
    final confirmed = await showGuardianConfirmDialog(
      context,
      title: 'Proteger $count apps remotamente?',
      message:
          'O aparelho adicionará todos os apps fora da proteção à lista quando receber o comando.',
      confirmLabel: 'Proteger todos',
      icon: Icons.verified_user,
      accentColor: AppColors.trustHigh,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submittingAll = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _repository.requestProtectApps(
        uid: widget.uid,
        deviceId: status.deviceId,
        requestedBy: user.uid,
        apps: targets,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1
                ? 'Comando enviado. 1 app será protegido quando o celular sincronizar.'
                : 'Comando enviado. $count apps serão protegidos quando o celular sincronizar.',
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
      if (mounted) setState(() => _submittingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layers = status.protectedLayers;
    final hasSnapshot = status.hasProtectedLayersSnapshot;
    final active = ProtectedLayerSnapshot.visibleSections(layers);
    final muted = !status.isOnline;
    final protectAllTargets =
        ProtectedLayerSnapshot.protectableUnprotectedTargets(layers);

    return SectionCard(
      accentColor: _layersTone(
        muted: muted,
        hasSnapshot: hasSnapshot,
        active: active,
        layers: layers,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Camadas protegidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasSnapshot && active.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CountBadge(
                  count: ProtectedLayerSnapshot.totalActiveApps(layers),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _subtitle(hasSnapshot: hasSnapshot, active: active),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            )
          else
            Text(
              _subtitle(hasSnapshot: hasSnapshot, active: active),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          if (protectAllTargets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _submittingAll
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _ProtectAllButton(
                      enabled: widget.protectAllEnabled,
                      muted: muted,
                      targetCount: protectAllTargets.length,
                      onPressed: () => _protectAll(protectAllTargets),
                    ),
            ),
          ],
          if (!hasSnapshot) ...[
            const SizedBox(height: 12),
            const _AwaitingSyncHint(),
          ] else if (active.isEmpty) ...[
            const SizedBox(height: 12),
            const _EmptyLayersHint(),
          ] else ...[
            const SizedBox(height: 12),
            _LayersGrid(
              uid: widget.uid,
              deviceId: status.deviceId,
              layers: active,
              muted: muted,
              extraProtectEnabled: widget.extraProtectEnabled,
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle({
    required bool hasSnapshot,
    required List<ProtectedLayerSummary> active,
  }) {
    if (!hasSnapshot) {
      return 'Abra o app no celular para sincronizar o resumo por categoria.';
    }
    if (active.isEmpty) {
      return 'Nenhum app instalado nas camadas';
    }

    final categories = active.length;
    final catWord = categories == 1 ? 'categoria' : 'categorias';
    final outside =
        ProtectedLayerSnapshot.totalUnprotectedApps(status.protectedLayers);

    // O total de apps já aparece no badge — evita repetir o número.
    if (outside == 0) {
      return 'Protegidos em $categories $catWord';
    }

    final outLabel = outside == 1
        ? '1 fora da proteção'
        : '$outside fora da proteção';
    return '$outLabel · $categories $catWord';
  }

  static Color _layersTone({
    required bool muted,
    required bool hasSnapshot,
    required List<ProtectedLayerSummary> active,
    required List<ProtectedLayerSummary> layers,
  }) {
    if (muted || !hasSnapshot) return AppColors.textMuted;
    if (active.isEmpty) return AppColors.textMuted;
    final outside = ProtectedLayerSnapshot.totalUnprotectedApps(layers);
    if (outside > 0) return AppColors.trustMedium;
    return AppColors.trustHigh;
  }
}

class _ProtectAllButton extends StatelessWidget {
  const _ProtectAllButton({
    required this.enabled,
    required this.muted,
    required this.targetCount,
    required this.onPressed,
  });

  final bool enabled;
  final bool muted;
  final int targetCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        enabled ? Icons.verified_user : Icons.lock_outline_rounded,
        size: 18,
      ),
      label: Text(
        targetCount == 1
            ? 'Proteger 1 app remotamente'
            : 'Proteger todos ($targetCount)',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.trustHigh,
        side: BorderSide(
          color: AppColors.trustHigh.withValues(
            alpha: muted || !enabled ? 0.25 : 0.45,
          ),
        ),
      ),
    );

    if (enabled) return button;

    return Tooltip(
      message: 'Disponível no plano Premium ativo',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(width: 8),
          const PremiumBadge(compact: true),
        ],
      ),
    );
  }
}

class _LayersGrid extends StatelessWidget {
  const _LayersGrid({
    required this.uid,
    required this.deviceId,
    required this.layers,
    required this.muted,
    required this.extraProtectEnabled,
  });

  final String uid;
  final String deviceId;
  final List<ProtectedLayerSummary> layers;
  final bool muted;
  final bool extraProtectEnabled;

  @override
  Widget build(BuildContext context) {
    return LiveStatusGrid(
      children: [
        for (final layer in layers)
          _LayerTile(
            uid: uid,
            deviceId: deviceId,
            layer: layer,
            muted: muted,
            extraProtectEnabled: extraProtectEnabled,
          ),
      ],
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.uid,
    required this.deviceId,
    required this.layer,
    required this.muted,
    required this.extraProtectEnabled,
  });

  final String uid;
  final String deviceId;
  final ProtectedLayerSummary layer;
  final bool muted;
  final bool extraProtectEnabled;

  @override
  Widget build(BuildContext context) {
    final accent = liveStatusAccent(
      muted: muted,
      ok: layer.isFullyProtected || layer.activeCount > 0,
      warn: !muted && layer.unprotectedCount > 0,
    );
    final value = layer.unprotectedCount == 0
        ? layer.protectedLabel
        : '${layer.activeCount} de ${layer.installedCount} protegidos';

    return LiveStatusTile(
      icon: layer.icon,
      label: layer.displayTitle,
      value: value,
      accent: accent,
      compact: true,
      onTap: () {
        showProtectedLayerDetailDialog(
          context,
          layer: layer,
          uid: uid,
          deviceId: deviceId,
          muted: muted,
          extraProtectEnabled: extraProtectEnabled,
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.trustHigh.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        count == 1 ? '1 app' : '$count apps',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.trustHigh,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AwaitingSyncHint extends StatelessWidget {
  const _AwaitingSyncHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Icon(Icons.hourglass_empty, size: 18, color: AppColors.textMuted),
         SizedBox(width: 8),
        Expanded(
          child: Text(
            'Abra o Guardian Sense no celular para sincronizar as camadas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLayersHint extends StatelessWidget {
  const _EmptyLayersHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Icon(Icons.info_outline, size: 18, color: AppColors.trustMedium),
         SizedBox(width: 8),
        Expanded(
          child: Text(
            'Nenhum app ativo nas camadas. Ajuste em Camadas protegidas no app.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
