import 'package:flutter/material.dart';

/// Pilares de proteção exibidos só na home do portal web (não espelha o app mobile).
class PortalHomeFeature {
  const PortalHomeFeature({
    required this.title,
    required this.blurb,
    required this.icon,
  });

  final String title;
  final String blurb;
  final IconData icon;
}

const portalHomeFeatures = [
  PortalHomeFeature(
    title: 'Detecção inteligente',
    blurb: 'Identifica sinais de risco antes do pior cenário.',
    icon: Icons.radar_outlined,
  ),
  PortalHomeFeature(
    title: 'Proteção offline',
    blurb: 'O celular continua protegido sem depender da internet.',
    icon: Icons.wifi_off_rounded,
  ),
  PortalHomeFeature(
    title: 'Recuperação por biometria',
    blurb: 'Desbloqueio seguro com biometria ou PIN de confiança.',
    icon: Icons.fingerprint_rounded,
  ),
  PortalHomeFeature(
    title: 'App Locker',
    blurb: 'Apps sensíveis bloqueados contra acesso indevido.',
    icon: Icons.lock_outline_rounded,
  ),
  PortalHomeFeature(
    title: 'Contenção automática',
    blurb: 'Resposta imediata quando um app protegido é violado.',
    icon: Icons.shield_outlined,
  ),
  PortalHomeFeature(
    title: 'Monitoramento contínuo',
    blurb: 'Runtime ativo enquanto o aparelho está em uso.',
    icon: Icons.visibility_outlined,
  ),
];
