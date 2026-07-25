import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
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
  String? _error;
  bool _ensuredTrial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ensuredTrial) return;
    final uid = AuthScope.of(context).user?.uid;
    if (uid == null) return;
    _ensuredTrial = true;
    _repo.ensureTrial(uid).catchError((Object e) {
      debugPrint('ensureTrial: $e');
      return SubscriptionEntitlement.newTrial(DateTime.now());
    });
  }

  Future<void> _generatePix() async {
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
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = e.message ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = e.toString();
      });
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
          return const GuardianScaffold(
            title: 'Guardian Premium',
            child: Center(child: Text('Faça login para assinar.')),
          );
        }

        return StreamBuilder<SubscriptionEntitlement?>(
          stream: _repo.watchEntitlement(user.uid),
          builder: (context, snap) {
            final entitlement = snap.data;
            final now = DateTime.now();
            final effective = entitlement?.effectiveStatusAt(now);
            final active = effective == SubscriptionStatus.active;

            return GuardianScaffold(
              title: 'Guardian Premium',
              subtitle: active
                  ? 'Assinatura ativa'
                  : 'Assinatura anual · PIX',
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    child: active
                        ? _ActiveCard(entitlement: entitlement!)
                        : _CheckoutColumn(
                            entitlement: entitlement,
                            charge: _charge,
                            creating: _creating,
                            error: _error,
                            onGenerate: _generatePix,
                            onCopy: _copyPix,
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.entitlement});

  final SubscriptionEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final expires = entitlement.expiresAt;
    final df = DateFormat('dd/MM/yyyy');
    final store = entitlement.store == 'pix'
        ? 'PIX'
        : entitlement.store == 'play'
            ? 'Google Play'
            : entitlement.store ?? '—';

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.trustHigh),
              const SizedBox(width: 10),
              Text(
                'Proteção ativa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            expires != null
                ? 'Válida até ${df.format(expires.toLocal())}.'
                : 'Assinatura anual ativa.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            'Canal: $store',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'A assinatura fica na sua conta. Trocar de aparelho não cancela '
            'o período pago.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutColumn extends StatelessWidget {
  const _CheckoutColumn({
    required this.entitlement,
    required this.charge,
    required this.creating,
    required this.error,
    required this.onGenerate,
    required this.onCopy,
  });

  final SubscriptionEntitlement? entitlement;
  final PixCharge? charge;
  final bool creating;
  final String? error;
  final VoidCallback onGenerate;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = entitlement?.effectiveStatusAt(now);
    final trialDays = entitlement?.trialDaysLeftCeil(now) ?? 0;

    String statusLine;
    switch (status) {
      case SubscriptionStatus.trial:
        statusLine = 'Trial: restam $trialDays dia${trialDays == 1 ? '' : 's'}.';
      case SubscriptionStatus.expired:
        statusLine = 'Trial encerrado — assine para continuar protegido.';
      case SubscriptionStatus.lapsed:
        statusLine = 'Assinatura vencida — renove com PIX.';
      case SubscriptionStatus.active:
        statusLine = '';
      case null:
        statusLine = 'Gere o PIX para ativar 12 meses na conta.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guardian Premium',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '12 meses à vista. Sem plano mensal.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                SubscriptionPricing.yearlyLabelBr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.trustHigh,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                SubscriptionPricing.monthlyLabelBr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              if (statusLine.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  statusLine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'O Guardian não processa reembolso pelo portal. '
                'Estornos do provedor PIX invalidam a assinatura automaticamente.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (charge == null) ...[
          Center(
            child: GuardianPillButton(
              label: 'Pagar com PIX',
              icon: Icons.qr_code_2_rounded,
              iconLeading: true,
              busy: creating,
              onPressed: creating ? null : onGenerate,
            ),
          ),
        ] else ...[
          _PixPanel(charge: charge!, onCopy: onCopy),
          const SizedBox(height: 12),
          Text(
            'Após o pagamento, a assinatura ativa sozinha nesta página. '
            'O app libera no próximo sync.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: creating ? null : onGenerate,
              child: Text(creating ? 'Gerando…' : 'Gerar novo QR'),
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.riskCritical, height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _PixPanel extends StatelessWidget {
  const _PixPanel({required this.charge, required this.onCopy});

  final PixCharge charge;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeQr(charge.encodedImage);

    return _Surface(
      child: Column(
        children: [
          Text(
            'Escaneie o QR ou use o copia e cola',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          if (bytes != null)
            Container(
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
          else
            Icon(
              Icons.qr_code_2_rounded,
              size: 120,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          const SizedBox(height: 16),
          SelectableText(
            charge.copyPaste,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          GuardianPillButton(
            label: 'Copiar código PIX',
            icon: Icons.copy_rounded,
            iconLeading: true,
            onPressed: onCopy,
          ),
          if (charge.expirationDate != null) ...[
            const SizedBox(height: 10),
            Text(
              'QR válido até ${charge.expirationDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
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

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: child,
    );
  }
}
