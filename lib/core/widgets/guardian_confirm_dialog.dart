import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';

/// Diálogo de confirmação com layout do portal (substitui [AlertDialog] genérico).
///
/// Se [onConfirm] for informado, o botão de confirmação exibe loading e só
/// fecha o diálogo quando o callback retornar `true`.
Future<bool> showGuardianConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? callout,
  required String confirmLabel,
  IconData icon = Icons.warning_amber_rounded,
  Color accentColor = AppColors.riskCritical,
  Future<bool> Function()? onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: onConfirm == null,
    builder: (ctx) => _GuardianConfirmDialog(
      title: title,
      message: message,
      callout: callout,
      confirmLabel: confirmLabel,
      icon: icon,
      accentColor: accentColor,
      onConfirm: onConfirm,
    ),
  );
  return result == true;
}

class _GuardianConfirmDialog extends StatefulWidget {
  const _GuardianConfirmDialog({
    required this.title,
    required this.message,
    required this.callout,
    required this.confirmLabel,
    required this.icon,
    required this.accentColor,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String? callout;
  final String confirmLabel;
  final IconData icon;
  final Color accentColor;
  final Future<bool> Function()? onConfirm;

  @override
  State<_GuardianConfirmDialog> createState() => _GuardianConfirmDialogState();
}

class _GuardianConfirmDialogState extends State<_GuardianConfirmDialog> {
  var _loading = false;

  Future<void> _handleConfirm() async {
    if (_loading) return;

    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _loading = true);
    var success = false;
    try {
      success = await onConfirm();
    } catch (error) {
      debugPrint('GuardianConfirmDialog onConfirm: $error');
      success = false;
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _loading = false);
  }

  void _handleCancel() {
    if (_loading) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.accentColor;

    return PopScope(
      canPop: !_loading,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogAccentIcon(
                      color: accentColor,
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: accentColor.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: _loading ? null : _handleCancel,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  widget.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                if (widget.callout != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _DialogAccentIcon(
                          color: AppColors.trustHigh,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GuardianLogo(size: 40),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.callout!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _handleCancel,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _handleConfirm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(
                            color: accentColor.withValues(
                              alpha: _loading ? 0.3 : 0.55,
                            ),
                          ),
                          backgroundColor: accentColor.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: _loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor.withValues(alpha: 0.9),
                                ),
                              )
                            : Icon(widget.icon, size: 18),
                        label: Text(widget.confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogAccentIcon extends StatelessWidget {
  const _DialogAccentIcon({
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}
