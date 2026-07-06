import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          label: 'Localizar aparelho',
          icon: Icons.map_outlined,
          onTap: () => context.go(AppRoutes.locate),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Ver eventos',
          icon: Icons.timeline_outlined,
          onTap: () => context.go(AppRoutes.events),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Configurações',
          icon: Icons.tune_outlined,
          onTap: () => context.go(AppRoutes.settings),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Dispositivos',
          icon: Icons.smartphone_outlined,
          onTap: () => context.go(AppRoutes.devices),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }
}
