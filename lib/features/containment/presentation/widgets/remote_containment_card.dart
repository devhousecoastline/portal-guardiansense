import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/widgets/celular_seguro_link.dart';
import 'package:guardian_portal/core/widgets/guardian_confirm_dialog.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/containment/data/device_commands_repository.dart';
import 'package:guardian_portal/features/containment/domain/device_command.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

class RemoteContainmentCard extends StatefulWidget {
  const RemoteContainmentCard({
    super.key,
    required this.uid,
    required this.deviceId,
    required this.status,
    this.compact = false,
    this.expandVertically = false,
  });

  final String uid;
  final String deviceId;
  final DeviceStatus status;
  final bool compact;
  final bool expandVertically;

  @override
  State<RemoteContainmentCard> createState() => _RemoteContainmentCardState();
}

class _RemoteContainmentCardState extends State<RemoteContainmentCard> {
  final _repository = DeviceCommandsRepository();
  Stream<DeviceCommand?>? _commandStream;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _commandStream =
        _repository.watchLatestCloseOyster(widget.uid, widget.deviceId);
  }

  @override
  void didUpdateWidget(covariant RemoteContainmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid || oldWidget.deviceId != widget.deviceId) {
      _commandStream =
          _repository.watchLatestCloseOyster(widget.uid, widget.deviceId);
    }
  }

  Future<void> _confirmAndSend() async {
    final confirmed = await showGuardianConfirmDialog(
      context,
      title: 'Fechar a ostra remotamente?',
      message:
          'O aparelho entrará em contenção: apps protegidos serão bloqueados '
          'quando o celular receber o comando.',
      callout: 'Só reabre no app ${AppConstants.appName}.',
      confirmLabel: 'Fechar ostra',
      icon: Icons.lock_rounded,
      accentColor: AppColors.riskCritical,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _repository.requestCloseOyster(
        uid: widget.uid,
        deviceId: widget.deviceId,
        requestedBy: user.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Comando enviado. O celular aplica quando sincronizar.',
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oysterClosed = widget.status.oysterClosed == true;

    return StreamBuilder<DeviceCommand?>(
      stream: _commandStream,
      builder: (context, snapshot) {
        final command = snapshot.data;

        return SectionCard(
          expandVertically: widget.expandVertically,
          padding: EdgeInsets.fromLTRB(
            20,
            widget.compact ? 12 : 18,
            20,
            widget.compact ? 10 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contenção remota',
                style: DashboardTypography.cardTitle(
                  context,
                  compact: widget.compact,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _headerSubtitle(
                  oysterClosed: oysterClosed,
                  command: command,
                ),
                style: DashboardTypography.cardSubtitle(context),
              ),
              SizedBox(height: widget.compact ? 8 : 12),
              if (widget.expandVertically)
                Expanded(
                  child: _buildBody(
                    context,
                    command: command,
                    oysterClosed: oysterClosed,
                    fillHeight: true,
                  ),
                )
              else
                _buildBody(
                  context,
                  command: command,
                  oysterClosed: oysterClosed,
                ),
            ],
          ),
        );
      },
    );
  }

  String _headerSubtitle({
    required bool oysterClosed,
    required DeviceCommand? command,
  }) {
    if (oysterClosed) {
      return 'O aparelho está em contenção ativa.';
    }
    if (command?.isPending == true) {
      return 'Comando enviado — aguardando o celular aplicar.';
    }
    if (command?.isFailed == true) {
      return 'O último comando não foi confirmado pelo aparelho.';
    }
    return widget.status.isOnline
        ? 'Ação de emergência se o aparelho saiu do seu controle.'
        : 'Celular offline — o comando ficará na fila até sincronizar.';
  }

  Widget _buildBody(
    BuildContext context, {
    required DeviceCommand? command,
    required bool oysterClosed,
    bool fillHeight = false,
  }) {
    if (oysterClosed) {
      return _OysterClosedPanel(
        status: widget.status,
        compact: widget.compact,
        fillHeight: fillHeight,
      );
    }

    if (command?.isPending == true) {
      return _TintedPanel(
        color: AppColors.riskElevated,
        icon: Icons.hourglass_top_rounded,
        title: 'Comando pendente',
        subtitle: widget.status.isOnline
            ? 'Aguardando o aparelho aplicar o fechamento…'
            : 'Será aplicado na próxima sincronização com a nuvem.',
        compact: widget.compact,
        fillHeight: fillHeight,
        trailing: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      );
    }

    if (command?.isFailed == true) {
      return _TintedPanel(
        color: AppColors.riskCritical,
        icon: Icons.error_outline_rounded,
        title: 'Falha ao aplicar',
        subtitle: command?.failureMessage ??
            'O aparelho não confirmou o fechamento.',
        compact: widget.compact,
        fillHeight: fillHeight,
        action: _ContainmentActionButton(
          loading: _submitting,
          onPressed: _confirmAndSend,
          label: 'Tentar novamente',
        ),
      );
    }

    return _TintedPanel(
      color: AppColors.riskCritical,
      icon: Icons.lock_outline_rounded,
      title: 'Fechar ostra remotamente',
      subtitle: widget.status.isOnline
          ? 'Bloqueia apps protegidos quando o celular receber o comando.'
          : 'O fechamento ocorre assim que o aparelho voltar online.',
      compact: widget.compact,
      fillHeight: fillHeight,
      action: _ContainmentActionButton(
        loading: _submitting,
        onPressed: _confirmAndSend,
        label: 'Fechar ostra',
      ),
    );
  }
}

class _OysterClosedPanel extends StatelessWidget {
  const _OysterClosedPanel({
    required this.status,
    required this.compact,
    required this.fillHeight,
  });

  final DeviceStatus status;
  final bool compact;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.trustHigh;
    final subtitle = status.isOnline
        ? 'Só reabre no app ${AppConstants.appName}.'
        : 'Contenção ativa. Última sync ${formatRelativeTime(status.lastSeen)}.';

    final hero = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact || fillHeight ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: fillHeight
          ? Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _OysterClosedHero(
                  color: color,
                  subtitle: subtitle,
                  compact: true,
                ),
              ),
            )
          : _OysterClosedHero(
              color: color,
              subtitle: subtitle,
              compact: compact,
            ),
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hero,
          SizedBox(height: compact ? 10 : 12),
          CelularSeguroCallout(compact: compact),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: hero),
        const SizedBox(height: 6),
        CelularSeguroCallout(compact: true),
      ],
    );
  }
}

class _OysterClosedHero extends StatelessWidget {
  const _OysterClosedHero({
    required this.color,
    required this.subtitle,
    required this.compact,
  });

  final Color color;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 22.0 : 28.0;
    final ring = compact ? 40.0 : 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ring,
          height: ring,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Icon(
            Icons.lock_rounded,
            size: iconSize,
            color: color,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          'Ostra fechada',
          textAlign: TextAlign.center,
          style: DashboardTypography.panelTitle(context, color: color),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: DashboardTypography.panelSubtitle(context),
        ),
      ],
    );
  }
}

class _TintedPanel extends StatelessWidget {
  const _TintedPanel({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.trailing,
    this.compact = false,
    this.fillHeight = false,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? trailing;
  final bool compact;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final sideBySide = !compact &&
        !fillHeight &&
        MediaQuery.sizeOf(context).width >= 640 &&
        action != null;

    return Container(
      width: double.infinity,
      height: fillHeight ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: fillHeight
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: _ContainmentHero(
                        color: color,
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        action: action,
                        trailing: trailing,
                        compact: compact,
                      ),
                    ),
                  ),
                );
              },
            )
          : sideBySide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PanelContent(
                        color: color,
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(width: 16),
                    action!,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PanelContent(
                            color: color,
                            icon: icon,
                            title: title,
                            subtitle: subtitle,
                            compact: compact,
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    if (action != null) ...[
                      SizedBox(height: compact ? 8 : 12),
                      Align(
                        alignment: Alignment.center,
                        child: action,
                      ),
                    ],
                  ],
                ),
    );
  }
}

/// Conteúdo centralizado do painel quando o card ocupa a altura da célula —
/// mesmo desenho do estado "Ostra fechada".
class _ContainmentHero extends StatelessWidget {
  const _ContainmentHero({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.compact,
    this.action,
    this.trailing,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;
  final Widget? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ring = compact ? 40.0 : 48.0;
    final iconSize = compact ? 22.0 : 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ring,
          height: ring,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, size: iconSize, color: color),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: DashboardTypography.panelTitle(context, color: color),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: DashboardTypography.panelSubtitle(context),
        ),
        if (trailing != null) ...[
          SizedBox(height: compact ? 8 : 10),
          trailing!,
        ],
        if (action != null) ...[
          SizedBox(height: compact ? 10 : 14),
          action!,
        ],
      ],
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: compact ? 18 : 20,
            color: color.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DashboardTypography.panelTitle(context, color: color),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                subtitle,
                style: DashboardTypography.panelSubtitle(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContainmentActionButton extends StatelessWidget {
  const _ContainmentActionButton({
    required this.loading,
    required this.onPressed,
    required this.label,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.riskCritical,
        side: BorderSide(
          color: AppColors.riskCritical.withValues(alpha: loading ? 0.25 : 0.55),
        ),
        backgroundColor: AppColors.riskCritical.withValues(alpha: 0.08),
        padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        visualDensity: VisualDensity.compact,
      ),
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.riskCritical.withValues(alpha: 0.8),
              ),
            )
          : const Icon(Icons.lock_rounded, size: 18),
      label: Text(label),
    );
  }
}
