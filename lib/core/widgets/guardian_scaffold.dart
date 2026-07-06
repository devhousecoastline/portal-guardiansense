import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/drawer_premium_teaser.dart';
import 'package:guardian_portal/core/widgets/drawer_account_tile.dart';
import 'package:guardian_portal/core/widgets/guardian_logo.dart';

/// Layout base do portal — sidebar em telas largas, drawer em mobile web.
class GuardianScaffold extends StatelessWidget {
  const GuardianScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final wide = AppLayout.isWide(viewportWidth);

    return Scaffold(
      body: Row(
        children: [
          if (wide) _SideNav(current: location),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mainWidth = constraints.maxWidth;
                final contentWidth = AppLayout.contentMaxWidth(mainWidth);
                final hPad = AppLayout.horizontalPadding(mainWidth);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: _TopBar(
                            title: title,
                            subtitle: subtitle,
                            showMenu: !wide,
                            current: location,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.showMenu,
    required this.current,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool showMenu;
  final String current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _openDrawer(context, current),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDrawer(BuildContext context, String current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _BrandHeader(),
                ),
                Expanded(
                  child: _NavList(
                    current: current,
                    onTap: () => Navigator.pop(sheetContext),
                  ),
                ),
                const DrawerPremiumTeaser(),
                DrawerAccountTile(
                  current: current,
                  onClose: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayout.sideNavWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: _BrandHeader(),
            ),
            Expanded(child: _NavList(current: current)),
            const DrawerPremiumTeaser(),
            DrawerAccountTile(current: current),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const GuardianLogo(size: 36),
            const SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.portalTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.current, this.onTap});

  final String current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final item in _navItems)
          _NavTile(
            item: item,
            selected: current == item.route,
            onTap: () {
              onTap?.call();
              if (current != item.route) {
                NavigationLoadingScope.of(context).go(context, item.route);
              }
            },
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

const _navItems = [
  _NavItem('Centro', Icons.shield_outlined, AppRoutes.dashboard),
  _NavItem('Localizar', Icons.map_outlined, AppRoutes.locate),
  _NavItem('Eventos', Icons.timeline_outlined, AppRoutes.events),
  _NavItem('Dispositivos', Icons.smartphone_outlined, AppRoutes.devices),
  _NavItem('Configurações', Icons.tune_outlined, AppRoutes.settings),
];

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final fg = selected ? AppColors.primary : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: fg),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
