import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_header_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';
import 'package:guardian_portal/features/subscription/data/pix_billing_service.dart';
import 'package:guardian_portal/features/subscription/data/subscription_repository.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_entitlement.dart';
import 'package:guardian_portal/features/subscription/domain/subscription_pricing.dart';
import 'package:intl/intl.dart';

/// Assinatura anual via PIX (P1) — QR + copia-cola; entitlement via webhook.
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final _repo = SubscriptionRepository();
  final _pix = PixBillingService();

  PixCharge? _charge;
  bool _creating = false;
  bool _confirming = false;
  String? _error;
  bool _ensuredTrial = false;
  bool _prefetchStarted = false;
  bool _prefetchComplete = false;
  SubscriptionEntitlement? _prefetchedEntitlement;
  Timer? _poll;
  int _pollCount = 0;
  bool _confirmInFlight = false;

  static const _pollInterval = Duration(seconds: 10);
  static const _maxPolls = 36;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = AuthScope.of(context).user?.uid;
    if (uid == null) return;

    if (!_prefetchStarted) {
      _prefetchStarted = true;
      unawaited(_repo.getEntitlement(uid).then((entitlement) {
        if (!mounted) return;
        setState(() {
          _prefetchedEntitlement = entitlement;
          _prefetchComplete = true;
        });
      }));
    }

    if (_ensuredTrial) return;
    _ensuredTrial = true;
    _repo.ensureTrial(uid).catchError((Object e) {
      debugPrint('ensureTrial: $e');
      return SubscriptionEntitlement.newTrial(DateTime.now());
    });
  }

  @override
  void dispose() {
    _stopPoll();
    super.dispose();
  }

  void _stopPoll() {
    _poll?.cancel();
    _poll = null;
  }

  void _startPoll() {
    _stopPoll();
    _pollCount = 0;
    _poll = Timer.periodic(_pollInterval, (_) {
      _pollCount += 1;
      if (_pollCount > _maxPolls) {
        _stopPoll();
        return;
      }
      unawaited(_confirmPix(silent: true));
    });
  }

  Future<void> _generatePix() async {
    _stopPoll();
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final charge = await _pix.createAnnualPixPayment();
      if (!mounted) return;
      setState(() {
        _charge = charge;
        _creating = false;
      });
      _startPoll();
      unawaited(_confirmPix(silent: true));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = _pixErrorMessage(e);
      });
      if (_charge != null) _startPoll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error =
            'Não foi possível gerar o PIX. Tente de novo em instantes.';
      });
      if (_charge != null) _startPoll();
    }
  }

  static String _pixErrorMessage(FirebaseFunctionsException e) {
    final raw = (e.message ?? e.code).trim();
    final lower = '${e.code} $raw'.toLowerCase();
    if (_isMissingCloudFunction(e)) {
      return 'A confirmação do PIX ainda não está na nuvem. '
          'Publique só as Functions para o “Já paguei” funcionar.';
    }
    if (e.code == 'failed-precondition' ||
        lower.contains('access token') ||
        lower.contains('authorization value not present') ||
        lower.contains('unauthorized')) {
      return raw.isNotEmpty
          ? raw
          : 'Access Token do Mercado Pago não configurado. '
              'Configure MERCADOPAGO_ACCESS_TOKEN no Firebase.';
    }
    if (e.code == 'internal' ||
        lower.contains('internal_error') ||
        lower.contains('internal_server_error') ||
        lower.contains('http is unavailable')) {
      return 'O Mercado Pago está instável agora. Tente gerar o PIX de novo '
          'em alguns minutos.';
    }
    if (raw.isEmpty) {
      return 'Não foi possível gerar o PIX. Tente de novo.';
    }
    return raw;
  }

  static String _confirmErrorMessage(FirebaseFunctionsException e) {
    if (_isMissingCloudFunction(e) || e.code == 'internal') {
      return 'A confirmação do PIX ainda não está na nuvem. '
          'Publique só as Functions para o “Já paguei” funcionar.';
    }
    final raw = (e.message ?? e.code).trim();
    if (raw.isEmpty) {
      return 'Não foi possível confirmar o PIX. Tente de novo em instantes.';
    }
    return raw;
  }

  static bool _isMissingCloudFunction(FirebaseFunctionsException e) {
    final lower = '${e.code} ${e.message ?? ''}'.toLowerCase();
    return e.code == 'not-found' ||
        e.code == 'unimplemented' ||
        lower.contains('not-found') ||
        lower.contains('not found');
  }

  Future<void> _confirmPix({required bool silent}) async {
    final id = _charge?.paymentId;
    if (id == null || id.isEmpty) return;
    if (_confirmInFlight) {
      if (silent) return;
      for (var i = 0; i < 50 && _confirmInFlight; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted || _confirmInFlight) return;
    }
    _confirmInFlight = true;

    if (!silent) {
      setState(() {
        _confirming = true;
        _error = null;
      });
    }

    try {
      final result = await _pix.confirmAnnualPixPayment(id);
      if (!mounted) return;
      if (result.active) {
        _stopPoll();
        setState(() => _confirming = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assinatura ativada.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (!silent) {
        setState(() {
          _confirming = false;
          _error = _pendingPixMessage(result.status);
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      debugPrint('confirmPix: ${e.code} ${e.message}');
      if (_isMissingCloudFunction(e) || e.code == 'internal') {
        _stopPoll();
        setState(() {
          _confirming = false;
          _error = _confirmErrorMessage(e);
        });
        return;
      }
      if (silent) return;
      setState(() {
        _confirming = false;
        _error = _confirmErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      if (silent) {
        debugPrint('confirmPix silent: $e');
        return;
      }
      setState(() {
        _confirming = false;
        _error =
            'Não foi possível confirmar o PIX. Tente de novo em instantes.';
      });
    } finally {
      _confirmInFlight = false;
    }
  }

  static String _pendingPixMessage(String status) {
    switch (status) {
      case 'rejected':
      case 'cancelled':
        return 'Este PIX não foi concluído. Gere um novo QR.';
      case 'refunded':
      case 'charged_back':
        return 'Este pagamento foi estornado.';
      default:
        return 'Ainda não identificamos o pagamento. Se já pagou, aguarde '
            'um instante e toque de novo.';
    }
  }

  Future<void> _copyPix() async {
    final payload = _charge?.copyPaste;
    if (payload == null || payload.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;
        if (user == null) {
          return GuardianScaffold(
            title: 'Guardian Premium',
            subtitle: 'Assinatura anual · PIX',
            child: SectionCard(
              accentColor: AppColors.textMuted,
              child: Text(
                'Faça login para assinar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          );
        }

        return StreamBuilder<SubscriptionEntitlement?>(
          stream: _repo.watchEntitlement(user.uid),
          builder: (context, snap) {
            final entitlement =
                snap.hasData ? snap.data : _prefetchedEntitlement;
            final waitingForEntitlement = entitlement == null &&
                (!_prefetchComplete || !snap.hasData);
            if (waitingForEntitlement) {
              return const _PremiumLoadingScaffold();
            }

            final now = DateTime.now();
            final effective = entitlement?.effectiveStatusAt(now);
            final active = effective == SubscriptionStatus.active;
            if (active && _poll != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _stopPoll();
              });
            }

            return GuardianScaffold(
              title: 'Guardian Premium',
              subtitle: active
                  ? 'Assinatura ativa na sua conta'
                  : 'Assinatura anual · pagamento via PIX',
              child: active
                  ? _ActiveView(entitlement: entitlement!)
                  : _CheckoutView(
                      entitlement: entitlement,
                      charge: _charge,
                      creating: _creating,
                      confirming: _confirming,
                      error: _error,
                      onGenerate: _generatePix,
                      onCopy: _copyPix,
                      onConfirm: () => unawaited(_confirmPix(silent: false)),
                    ),
            );
          },
        );
      },
    );
  }
}

class _PremiumLoadingScaffold extends StatelessWidget {
  const _PremiumLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return GuardianScaffold(
      title: 'Guardian Premium',
      subtitle: 'Carregando…',
      child: SectionCard(
        accentColor: AppColors.textMuted,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.entitlement});

  final SubscriptionEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final started = entitlement.startedAt ?? entitlement.trialStartedAt;
    final expires = entitlement.expiresAt;
    final df = DateFormat('dd/MM/yyyy');
    final store = entitlement.store == 'pix'
        ? 'PIX'
        : entitlement.store == 'play'
            ? 'Google Play'
            : entitlement.store ?? '—';

    final startedLabel = df.format(started.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          accentColor: AppColors.trustHigh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                icon: Icons.verified_outlined,
                label: 'Proteção ativa',
                trailing: SizedBox(
                  width: GuardianHeaderChip.alignedWidth(context, 'Ativo'),
                  child: GuardianHeaderChip(
                    label: 'Ativo',
                    color: AppColors.trustHigh,
                    icon: Icons.workspace_premium_outlined,
                    expand: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tiles = <Widget>[
                    _InfoTile(
                      icon: Icons.play_circle_outline,
                      label: 'Início',
                      value: startedLabel,
                    ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Válida até',
                      value: expires != null
                          ? df.format(expires.toLocal())
                          : '—',
                    ),
                    _InfoTile(
                      icon: Icons.storefront_outlined,
                      label: 'Canal',
                      value: store,
                    ),
                  ];
                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          tiles[i],
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _Footnote(
          text:
              'A assinatura fica na sua conta. Trocar de aparelho não cancela '
              'o período pago.',
        ),
      ],
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView({
    required this.entitlement,
    required this.charge,
    required this.creating,
    required this.confirming,
    required this.error,
    required this.onGenerate,
    required this.onCopy,
    required this.onConfirm,
  });

  final SubscriptionEntitlement? entitlement;
  final PixCharge? charge;
  final bool creating;
  final bool confirming;
  final String? error;
  final VoidCallback onGenerate;
  final VoidCallback onCopy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final status = entitlement?.effectiveStatusAt(now);
    final trialDays = entitlement?.trialDaysLeftCeil(now) ?? 0;

    final (pillLabel, statusLine, color, pillIcon) = switch (status) {
      SubscriptionStatus.trial => (
          'Trial',
          'Restam $trialDays dia${trialDays == 1 ? '' : 's'} grátis.',
          AppColors.trustMedium,
          Icons.timelapse_rounded,
        ),
      SubscriptionStatus.expired => (
          'Trial encerrado',
          'Assine para continuar com a proteção completa.',
          AppColors.riskCritical,
          Icons.hourglass_disabled_outlined,
        ),
      SubscriptionStatus.lapsed => (
          'Vencida',
          'Renove com PIX para reativar.',
          AppColors.riskCritical,
          Icons.event_busy_outlined,
        ),
      SubscriptionStatus.active => (
          'Ativo',
          '',
          AppColors.trustHigh,
          Icons.workspace_premium_outlined,
        ),
      null => (
          'Plano',
          'Gere o PIX para ativar 12 meses na conta.',
          AppColors.primary,
          Icons.workspace_premium_outlined,
        ),
    };

    final showingPix = charge != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!showingPix)
          SectionCard(
            accentColor: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CardTitle(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Assinatura anual',
                  trailing: SizedBox(
                    width: GuardianHeaderChip.alignedWidth(context, pillLabel),
                    child: GuardianHeaderChip(
                      label: pillLabel,
                      color: color,
                      icon: pillIcon,
                      expand: true,
                    ),
                  ),
                  centered: true,
                ),
                const SizedBox(height: 12),
                Text(
                  '12 meses à vista. Sem plano mensal.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  SubscriptionPricing.yearlyLabelBr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.trustHigh,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SubscriptionPricing.monthlyLabelBr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                if (statusLine.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    statusLine,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          )
        else
          SectionCard(
            accentColor: color,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    statusLine.isNotEmpty
                        ? statusLine
                        : SubscriptionPricing.yearlyLabelBr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: GuardianHeaderChip.alignedWidth(context, pillLabel),
                  child: GuardianHeaderChip(
                    label: pillLabel,
                    color: color,
                    icon: pillIcon,
                    expand: true,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (!showingPix)
          SectionCard(
            accentColor: AppColors.trustHigh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _CardTitle(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Pagamento PIX',
                  centered: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gere o QR Code para pagar à vista e ativar 12 meses '
                  'na sua conta.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                GuardianPillButton(
                  label: 'Pagar com PIX',
                  icon: Icons.qr_code_2_rounded,
                  iconLeading: true,
                  busy: creating,
                  onPressed: creating ? null : onGenerate,
                ),
              ],
            ),
          )
        else
          _PixPanel(
            charge: charge!,
            creating: creating,
            confirming: confirming,
            onCopy: onCopy,
            onRegenerate: onGenerate,
            onConfirm: onConfirm,
          ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.riskCritical,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        const _Footnote(
          text:
              'Após o pagamento, a assinatura ativa sozinha. Estornos PIX '
              'cancelam o plano automaticamente.',
        ),
      ],
    );
  }
}

class _PixPanel extends StatelessWidget {
  const _PixPanel({
    required this.charge,
    required this.creating,
    required this.confirming,
    required this.onCopy,
    required this.onRegenerate,
    required this.onConfirm,
  });

  final PixCharge charge;
  final bool creating;
  final bool confirming;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _decodeQr(charge.encodedImage);
    final expiresLabel = _formatExpiration(charge.expirationDate);

    return SectionCard(
      accentColor: AppColors.trustHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            icon: Icons.qr_code_2_rounded,
            label: 'Pagar com PIX',
          ),
          const SizedBox(height: 6),
          Text(
            'Escaneie o QR ou use o copia e cola',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: bytes != null
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Image.memory(
                      bytes,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  )
                : Icon(
                    Icons.qr_code_2_rounded,
                    size: 120,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.9),
              ),
            ),
            child: SelectableText(
              charge.copyPaste,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.35,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GuardianPillButton(
              label: 'Copiar código PIX',
              icon: Icons.copy_rounded,
              iconLeading: true,
              onPressed: onCopy,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GuardianPillButton(
              label: confirming ? 'Verificando…' : 'Já paguei',
              icon: Icons.check_circle_outline_rounded,
              iconLeading: true,
              busy: confirming,
              onPressed: confirming ? null : onConfirm,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aguardando o pagamento. A assinatura ativa sozinha após a '
            'confirmação.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          if (expiresLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              'QR válido até $expiresLabel',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: creating ? null : onRegenerate,
              child: Text(creating ? 'Gerando…' : 'Gerar novo QR'),
            ),
          ),
        ],
      ),
    );
  }

  static String? _formatExpiration(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    return DateFormat("dd/MM/yyyy 'às' HH:mm").format(parsed.toLocal());
  }

  static Uint8List? _decodeQr(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    var raw = encoded.trim();
    final comma = raw.indexOf(',');
    if (raw.startsWith('data:') && comma > 0) {
      raw = raw.substring(comma + 1);
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.label,
    this.trailing,
    this.centered = false,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );

    return Row(
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 22),
        const SizedBox(width: 10),
        if (centered) title else Expanded(child: title),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
      ],
    );
  }
}
