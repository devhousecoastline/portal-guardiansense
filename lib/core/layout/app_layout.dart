/// Breakpoints e larguras do portal em telas largas.
abstract final class AppLayout {
  static const double sideNavWidth = 240;
  static const double wideBreakpoint = 900;
  static const double dashboardRowBreakpoint = 960;
  static const double checklistTwoColBreakpoint = 720;
  static const double locateSplitBreakpoint = 1100;

  /// Largura útil da área principal (sem sidebar).
  static double mainAreaWidth(double viewportWidth) {
    if (viewportWidth < wideBreakpoint) return viewportWidth;
    return viewportWidth - sideNavWidth;
  }

  /// Largura máxima do conteúdo — cresce em monitores maiores.
  static double contentMaxWidth(double mainAreaWidth) {
    const pad = 48.0;
    final usable = mainAreaWidth - pad;
    if (usable <= 720) return usable.clamp(0, double.infinity);
    if (usable <= 1040) return usable;
    if (usable <= 1360) return 1000;
    if (usable <= 1680) return 1200;
    if (usable <= 2100) return 1360;
    return 1520;
  }

  static double horizontalPadding(double mainAreaWidth) {
    if (mainAreaWidth < 600) return 16;
    if (mainAreaWidth < 1200) return 24;
    return 32;
  }

  static bool isWide(double viewportWidth) => viewportWidth >= wideBreakpoint;

  static bool isDashboardRow(double viewportWidth) =>
      mainAreaWidth(viewportWidth) >= dashboardRowBreakpoint;

  static bool isLocateSplit(double viewportWidth) =>
      mainAreaWidth(viewportWidth) >= locateSplitBreakpoint;
}
