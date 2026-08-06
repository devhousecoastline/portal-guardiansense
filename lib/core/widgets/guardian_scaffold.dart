import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_routes.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/theme_scope.dart';
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
    this.subtitleTrailing,
    this.onBack,
    this.onRefresh,
    this.fitViewport = false,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleTrailing;
  final VoidCallback? onBack;
  final Widget child;
  final Future<void> Function()? onRefresh;

  /// Preenche a altura útil sem scroll (grade 2×2 do Centro em notebook).
  final bool fitViewport;

  @override
  Widget build(BuildContext context) {
    // AppColors lê paleta estática — depende do ThemeScope para rebuild ao trocar tema.
    ThemeScope.of(context);

    final location = GoRouterState.of(context).matchedLocation;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final wide = AppLayout.isWide(viewportWidth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.loginBackgroundEdge
          : AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isDark) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.12, -0.06),
                  radius: 1.08,
                  colors: [
                    AppColors.loginBackgroundCenter,
                    AppColors.loginBackgroundMid,
                    AppColors.loginBackgroundEdge,
                  ],
                  stops: const [0.0, 0.52, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: wide
                      ? const Alignment(-0.42, -0.12)
                      : const Alignment(0, -0.2),
                  radius: wide ? 0.7 : 0.75,
                  colors: [
                    AppColors.trustHigh.withValues(alpha: 0.07),
                    AppColors.trustHigh.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            if (wide)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.55, -0.1),
                    radius: 0.85,
                    colors: [
                      AppColors.trustHigh.withValues(alpha: 0.05),
                      AppColors.trustHigh.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
          ],
          Row(
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
                              constraints:
                                  BoxConstraints(maxWidth: contentWidth),
                              child: _TopBar(
                                title: title,
                                subtitle: subtitle,
                                subtitleTrailing: subtitleTrailing,
                                onBack: onBack,
                                showMenu: !wide,
                                current: location,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ViewportContent(
                            fitViewport: fitViewport,
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              8,
                              hPad,
                              _contentBottomPadding(context, fitViewport),
                            ),
                            maxWidth: contentWidth,
                            onRefresh: onRefresh,
                            child: child,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _contentBottomPadding(BuildContext context, bool fitViewport) {
    if (fitViewport) return 12;
    final height = MediaQuery.sizeOf(context).height;
    if (height < AppLayout.dashboardCompactHeightBreakpoint) return 16;
    return 32;
  }
}

class _ViewportContent extends StatelessWidget {
  const _ViewportContent({
    required this.fitViewport,
    required this.padding,
    required this.maxWidth,
    required this.child,
    this.onRefresh,
  });

  final bool fitViewport;
  final EdgeInsets padding;
  final double maxWidth;
  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final alignedChild = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (fitViewport) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final innerHeight = (constraints.maxHeight - padding.vertical)
              .clamp(0.0, double.infinity);
          final fittedChild = Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxWidth,
              height: innerHeight,
              child: child,
            ),
          );

          if (onRefresh != null) {
            return RefreshIndicator(
              onRefresh: onRefresh!,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                children: [
                  SizedBox(
                    height: innerHeight,
                    child: fittedChild,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: padding,
            child: fittedChild,
          );
        },
      );
    }

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          child: alignedChild,
        ),
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: alignedChild,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.showMenu,
    required this.current,
    this.subtitle,
    this.subtitleTrailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleTrailing;
  final VoidCallback? onBack;
  final bool showMenu;
  final String current;

  @override
  Widget build(BuildContext context) {
    final isHome = current == AppRoutes.dashboard;

    return Container(
      padding: EdgeInsets.fromLTRB(isHome && !showMenu ? 16 : 8, 20, 24, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isHome)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Voltar',
              onPressed: () => _handleBack(context),
            ),
          if (showMenu)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
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
          if (subtitleTrailing != null) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: subtitleTrailing!,
            ),
          ],
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (current == AppRoutes.eventsDetails ||
        current.startsWith('${AppRoutes.eventsDetails}/')) {
      context.go(AppRoutes.events);
      return;
    }
    context.go(AppRoutes.dashboard);
  }

  void _openDrawer(BuildContext context, String current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark
          ? AppColors.loginBackgroundMid
          : AppColors.surface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: AppLayout.sideNavWidth,
      decoration: BoxDecoration(
        color: isDark ? null : AppColors.surface,
        gradient: isDark
            ? RadialGradient(
                center: const Alignment(-0.2, -0.35),
                radius: 1.15,
                colors: [
                  AppColors.loginBackgroundCenter,
                  AppColors.loginBackgroundMid,
                  AppColors.loginBackgroundEdge,
                ],
                stops: const [0.0, 0.55, 1.0],
              )
            : null,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isDark)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.15, -0.25),
                  radius: 0.9,
                  colors: [
                    AppColors.trustHigh.withValues(alpha: 0.06),
                    AppColors.trustHigh.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          SafeArea(
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
        ],
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
            selected: _isNavSelected(current, item.route),
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
  _NavItem('Localizar', Icons.search_outlined, AppRoutes.locate),
  _NavItem('Eventos', Icons.timeline_outlined, AppRoutes.events),
  _NavItem('Dispositivos', Icons.smartphone_outlined, AppRoutes.devices),
  _NavItem('Configurações', Icons.tune_outlined, AppRoutes.settings),
];

bool _isNavSelected(String current, String route) {
  if (current == route) return true;
  if (route == AppRoutes.events &&
      (current == AppRoutes.eventsDetails ||
          current.startsWith('${AppRoutes.eventsDetails}/'))) {
    return true;
  }
  return false;
}

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
            padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: fg),
                 SizedBox(width: 12),
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
