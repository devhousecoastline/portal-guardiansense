import 'dart:async';

import 'package:flutter/material.dart';

/// Reconstrói o filho periodicamente para recalcular `isOnline` pelo relógio.
///
/// O Firestore só emite quando o documento muda; sem este tick, o portal pode
/// mostrar "online" indefinidamente após o celular parar de sincronizar.
class OnlineRefresh extends StatefulWidget {
  const OnlineRefresh({
    super.key,
    required this.builder,
    this.interval = const Duration(seconds: 30),
  });

  final Widget Function(BuildContext context) builder;
  final Duration interval;

  @override
  State<OnlineRefresh> createState() => _OnlineRefreshState();
}

class _OnlineRefreshState extends State<OnlineRefresh> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
