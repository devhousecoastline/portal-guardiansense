import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_pill_button.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/devices/data/device_pairing_repository.dart';
import 'package:guardian_portal/features/devices/domain/device_pairing.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Empty state do portal: QR de confirmação de identidade.
///
/// Sem este passo o aparelho não sincroniza (Centro, Eventos, Localizar).
class DevicePairingCard extends StatefulWidget {
  const DevicePairingCard({super.key, required this.uid});

  final String uid;

  @override
  State<DevicePairingCard> createState() => _DevicePairingCardState();
}

class _DevicePairingCardState extends State<DevicePairingCard> {
  final _repo = DevicePairingRepository();
  StreamSubscription<DevicePairing?>? _sub;
  Timer? _ticker;
  DevicePairing? _pairing;
  bool _busy = false;
  bool _ensured = false;
  String? _autoRefreshedId;
  String? _error;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _sub = _repo.watchLatest(widget.uid).listen((pairing) {
      if (!mounted) return;
      setState(() => _pairing = pairing);
      if (!_ensured) {
        unawaited(_ensure());
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now().toUtc());
      final pairing = _pairing;
      if (pairing != null &&
          !pairing.used &&
          pairing.isExpiredAt(_now) &&
          !_busy &&
          _autoRefreshedId != pairing.id) {
        _autoRefreshedId = pairing.id;
        unawaited(_ensure(refresh: true));
      }
    });
    unawaited(_ensure());
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _ensure({bool refresh = false}) async {
    if (_busy) return;
    final current = _pairing;
    if (!refresh && current != null && current.isActiveAt(_now)) {
      _ensured = true;
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await _repo.create(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _pairing = created;
        _ensured = true;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível gerar o QR. Tente de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _mapError(FirebaseFunctionsException e) {
    final raw = (e.message ?? e.code).trim();
    if (raw.isEmpty || raw.toLowerCase() == 'internal') {
      return 'Não foi possível gerar o QR. Tente de novo.';
    }
    return raw;
  }

  Future<void> _copyCode() async {
    final code = _pairing?.code;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: _body(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: card,
        );
        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }
        return Center(
          child: SingleChildScrollView(child: content),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    final pairing = _pairing;
    if (pairing != null && pairing.used) {
      return const _ConfirmedBody();
    }

    final active = pairing != null && pairing.isActiveAt(_now);
    final remaining = active ? pairing.expiresAt.difference(_now) : Duration.zero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.qr_code_2_rounded,
          size: 36,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 12),
        Text(
          'Confirme a identidade do aparelho',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'O portal só sincroniza depois que você escanear este QR no '
          'Guardian Sense, com a mesma conta. Até lá o aparelho não aparece.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (active)
          _QrBlock(url: pairing.pairingUrl, code: pairing.code)
        else if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(),
          )
        else
          Icon(
            Icons.qr_code_2_rounded,
            size: 120,
            color: AppColors.textMuted.withValues(alpha: 0.45),
          ),
        if (active) ...[
          const SizedBox(height: 14),
          Text(
            _remainingLabel(remaining),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              GuardianPillButton(
                label: 'Copiar código',
                icon: Icons.copy_rounded,
                iconLeading: true,
                compact: true,
                onPressed: _copyCode,
              ),
              GuardianPillButton(
                label: 'Novo QR',
                icon: Icons.refresh_rounded,
                iconLeading: true,
                compact: true,
                neutral: true,
                busy: _busy,
                onPressed: _busy ? null : () => _ensure(refresh: true),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.riskCritical,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 10),
          GuardianPillButton(
            label: 'Tentar de novo',
            icon: Icons.refresh_rounded,
            iconLeading: true,
            compact: true,
            busy: _busy,
            onPressed: _busy ? null : () => _ensure(refresh: true),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'No app: entre com esta conta → Vincular aparelho → escanear.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
        ),
      ],
    );
  }

  static String _remainingLabel(Duration remaining) {
    final seconds = remaining.inSeconds.clamp(0, 24 * 3600);
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return 'Válido por $m:$ss';
  }
}

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.url, required this.code});

  final String url;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: QrImageView(
            data: url,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF102018),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF102018),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
        ),
      ],
    );
  }
}

class _ConfirmedBody extends StatelessWidget {
  const _ConfirmedBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, size: 40, color: AppColors.trustHigh),
        const SizedBox(height: 12),
        Text(
          'Identidade confirmada',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'O aparelho está ativo e verificado. A sincronização aparece '
          'assim que o Guardian Sense enviar o primeiro snapshot.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
