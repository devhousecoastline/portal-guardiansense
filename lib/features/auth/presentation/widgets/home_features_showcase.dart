import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/features/auth/domain/portal_home_feature.dart';

/// Carrossel infinito com destaque no card central — exclusivo do portal web.
class HomeFeaturesShowcase extends StatefulWidget {
  const HomeFeaturesShowcase({super.key});

  @override
  State<HomeFeaturesShowcase> createState() => _HomeFeaturesShowcaseState();
}

class _HomeFeaturesShowcaseState extends State<HomeFeaturesShowcase> {
  static const _itemCount = 12000;

  static int get _initialPage {
    const base = 6000;
    final len = portalHomeFeatures.length;
    return base - (base % len);
  }

  PageController? _controller;
  Timer? _autoPlay;
  int _rawPage = _initialPage;
  int _index = 0;
  bool _hovering = false;
  double? _viewportFraction;

  @override
  void initState() {
    super.initState();
    _rawPage = _initialPage;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAutoPlay());
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _scheduleAutoPlay() {
    _autoPlay?.cancel();
    _autoPlay = Timer(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;
      if (_hovering) {
        _scheduleAutoPlay();
        return;
      }
      await _advance();
      if (mounted) _scheduleAutoPlay();
    });
  }

  PageController _ensureController(double viewportFraction) {
    if (_viewportFraction == viewportFraction && _controller != null) {
      return _controller!;
    }
    _viewportFraction = viewportFraction;
    _controller?.dispose();
    _controller = PageController(
      viewportFraction: viewportFraction,
      initialPage: _rawPage,
    );
    return _controller!;
  }

  Future<void> _advance() async {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    if (controller.position.isScrollingNotifier.value) return;

    final next = _rawPage + 1;
    await controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _step(int delta) async {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    await controller.animateToPage(
      _rawPage + delta,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _rawPage = page;
      _index = page % portalHomeFeatures.length;
    });
    _recenterIfNeeded(page);
  }

  void _recenterIfNeeded(int page) {
    final edge = portalHomeFeatures.length * 3;
    if (page > edge && page < _itemCount - edge) return;

    final target = _initialPage + (page % portalHomeFeatures.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _controller;
      if (controller == null || !controller.hasClients) return;
      controller.jumpToPage(target);
      _rawPage = target;
    });
  }

  double _viewportFractionFor(double width) {
    if (width >= 960) return 0.38;
    if (width >= 720) return 0.58;
    return 0.84;
  }

  bool _showArrows(double width) => width >= 720;

  double _focusForIndex(PageController controller, int index) {
    if (!controller.position.haveDimensions) {
      return index == _rawPage ? 1 : 0;
    }
    final page = controller.page ?? _rawPage.toDouble();
    final delta = (page - index).abs().clamp(0.0, 1.0);
    return Curves.easeOut.transform(1 - delta);
  }

  int _featureIndex(int page) => page % portalHomeFeatures.length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final controller = _ensureController(_viewportFractionFor(width));

    final carousel = SizedBox(
      height: 212,
      child: PageView.builder(
        controller: controller,
        itemCount: _itemCount,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, page) {
          final feature = portalHomeFeatures[_featureIndex(page)];
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final focus = _focusForIndex(controller, page);
              final scale = 0.78 + (0.22 * focus);
              final opacity = 0.32 + (0.68 * focus);

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final focus = _focusForIndex(controller, page);
                return _HomeFeatureCard(feature: feature, focus: focus);
              },
            ),
          );
        },
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        _autoPlay?.cancel();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _scheduleAutoPlay();
      },
      child: Column(
        children: [
          if (_showArrows(width))
            Row(
              children: [
                _CarouselArrow(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _step(-1),
                ),
                const SizedBox(width: 10),
                Expanded(child: carousel),
                const SizedBox(width: 10),
                _CarouselArrow(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _step(1),
                ),
              ],
            )
          else
            carousel,
          const SizedBox(height: 14),
          _PageDots(count: portalHomeFeatures.length, index: _index),
        ],
      ),
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({
    required this.feature,
    required this.focus,
  });

  final PortalHomeFeature feature;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.trustHigh;
    final borderColor = Color.lerp(
      accent.withValues(alpha: 0.28),
      accent,
      focus,
    )!;
    final bgAlpha = 0.55 + (0.25 * focus);
    final iconBgAlpha = 0.12 + (0.1 * focus);
    final iconColor = Color.lerp(AppColors.primary, accent, focus)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2 + (0.8 * focus),
        ),
        boxShadow: focus > 0.55
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18 * focus),
                  blurRadius: 22 * focus,
                  offset: Offset(0, 8 * focus),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: iconBgAlpha),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            feature.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Color.lerp(
                    AppColors.textMuted,
                    AppColors.textPrimary,
                    focus,
                  ),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            feature.blurb,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Color.lerp(
                    AppColors.textMuted.withValues(alpha: 0.65),
                    AppColors.textMuted,
                    focus,
                  ),
                  height: 1.4,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? AppColors.trustHigh
                : AppColors.textMuted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
