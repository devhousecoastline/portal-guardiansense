import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardian_portal/core/widgets/matrix_refresh_bar.dart';

/// Dispara o feedback visual do [OnlineRefresh] (ex.: pull-to-refresh).
class OnlineRefreshController {
  Future<void> Function()? _refresh;

  Future<void> refresh() async {
    final action = _refresh;
    if (action != null) await action();
  }

  void _attach(Future<void> Function() refresh) => _refresh = refresh;

  void _detach() => _refresh = null;
}

/// Reconstrói o filho periodicamente para recalcular `isOnline` pelo relógio.
///
/// O Firestore só emite quando o documento muda; sem este tick, o portal pode
/// mostrar "online" indefinidamente após o celular parar de sincronizar.
///
/// [builder] recebe `isRefreshing` durante o tick (~450 ms) para exibir feedback
/// sem recriar streams do Firestore (evita piscar a tela).
class OnlineRefresh extends StatefulWidget {
  const OnlineRefresh({
    super.key,
    required this.builder,
    this.controller,
    this.interval = const Duration(seconds: 30),
    this.tickVisibleFor = const Duration(milliseconds: 850),
  });

  final Widget Function(BuildContext context, bool isRefreshing) builder;
  final OnlineRefreshController? controller;
  final Duration interval;
  final Duration tickVisibleFor;

  @override
  State<OnlineRefresh> createState() => _OnlineRefreshState();
}

class _OnlineRefreshState extends State<OnlineRefresh> {
  Timer? _timer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(refreshNow);
    _timer = Timer.periodic(widget.interval, (_) => refreshNow());
  }

  @override
  void didUpdateWidget(covariant OnlineRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(refreshNow);
    }
  }

  Future<void> refreshNow() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(widget.tickVisibleFor);
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _isRefreshing);
}

/// Posição da faixa Matrix durante o tick de atualização.
enum RefreshTickBarPlacement {
  top,
  bottom,
}

/// Faixa estilo Matrix durante o tick de atualização online.
class RefreshTickBar extends StatelessWidget {
  const RefreshTickBar({
    super.key,
    required this.visible,
    this.placement = RefreshTickBarPlacement.top,
    this.reserveSpace = false,
    this.alwaysVisible = false,
  });

  final bool visible;
  final RefreshTickBarPlacement placement;

  /// Mantém altura fixa para o tick não empurrar o conteúdo acima.
  final bool reserveSpace;

  /// Exibe a faixa Matrix o tempo todo (mais intensa quando [visible]).
  final bool alwaysVisible;

  static const double _barHeight = 14;
  static const double _padding = 8;
  static double get reservedHeight => _barHeight + _padding;

  @override
  Widget build(BuildContext context) {
    final atBottom = placement == RefreshTickBarPlacement.bottom;

    if (reserveSpace) {
      final showBar = alwaysVisible || visible;
      return SizedBox(
        height: reservedHeight,
        child: Padding(
          padding: EdgeInsets.only(top: atBottom ? _padding : 0),
          child: showBar
              ? MatrixRefreshBar(
                  intensity: visible
                      ? MatrixRefreshIntensity.active
                      : MatrixRefreshIntensity.ambient,
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: atBottom ? Alignment.bottomCenter : Alignment.topCenter,
      child: visible
          ? Padding(
              padding: EdgeInsets.only(
                top: atBottom ? 8 : 0,
                bottom: atBottom ? 0 : 8,
              ),
              child: MatrixRefreshBar(
                intensity: visible
                    ? MatrixRefreshIntensity.active
                    : MatrixRefreshIntensity.ambient,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
