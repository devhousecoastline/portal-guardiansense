import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
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
  });

  final String uid;
  final String deviceId;
  final DeviceStatus status;

  @override
  State<RemoteContainmentCard> createState() => _RemoteContainmentCardState();
}

class _RemoteContainmentCardState extends State<RemoteContainmentCard> {
  final _repository = DeviceCommandsRepository();
  var _submitting = false;

  Future<void> _confirmAndSend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Fechar a ostra remotamente?'),
        content: const Text(
          'O aparelho entrará em contenção: apps protegidos serão bloqueados '
          'quando o celular receber o comando.\n\n'
          'Só reabra no app Android, com biometria ou PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.riskCritical,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fechar ostra'),
          ),
        ],
      ),
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
      stream: _repository.watchLatestCloseOyster(widget.uid, widget.deviceId),
      builder: (context, snapshot) {
        final command = snapshot.data;
        final body = _buildBody(context, command: command, oysterClosed: oysterClosed);

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    oysterClosed ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: oysterClosed ? AppColors.trustHigh : AppColors.riskCritical,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Contenção remota',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required DeviceCommand? command,
    required bool oysterClosed,
  }) {
    if (oysterClosed) {
      return _StatusBlock(
        icon: Icons.check_circle_outline,
        color: AppColors.trustHigh,
        title: 'Ostra fechada',
        subtitle: widget.status.isOnline
            ? 'O aparelho está em contenção. Reabra somente no celular.'
            : 'Contenção ativa. Última sync ${formatRelativeTime(widget.status.lastSeen)}.',
      );
    }

    if (command?.isPending == true) {
      return _StatusBlock(
        icon: Icons.hourglass_top_rounded,
        color: AppColors.riskElevated,
        title: 'Comando pendente',
        subtitle: widget.status.isOnline
            ? 'Aguardando o aparelho aplicar o fechamento…'
            : 'Celular offline — o comando será aplicado na próxima sync.',
        trailing: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      );
    }

    if (command?.isFailed == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBlock(
            icon: Icons.error_outline,
            color: AppColors.riskCritical,
            title: 'Falha ao aplicar',
            subtitle: command?.failureMessage ??
                'O aparelho não confirmou o fechamento. Tente novamente.',
          ),
          const SizedBox(height: 12),
          _ActionButton(
            loading: _submitting,
            onPressed: _confirmAndSend,
            label: 'Tentar novamente',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.status.isOnline
              ? 'Use se o aparelho foi roubado ou está fora do seu controle.'
              : 'O celular está offline. O comando ficará na fila até sincronizar.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 14),
        _ActionButton(
          loading: _submitting,
          onPressed: _confirmAndSend,
          label: 'Fechar ostra agora',
        ),
      ],
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.loading,
    required this.onPressed,
    required this.label,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.riskCritical,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.lock_rounded),
      label: Text(label),
    );
  }
}
