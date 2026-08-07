import 'package:guardian_portal/core/layout/app_layout.dart';

/// Faixas de layout do Centro — largura útil + altura da viewport.
enum DashboardLayoutProfile {
  /// Coluna única (mobile / janela estreita).
  mobile,

  /// Grade 2×2 compacta (notebook / janela baixa).
  notebook,

  /// Hero + setup em linha; contenção e checklist lado a lado (desktop).
  desktop,
}

/// Decisões de layout e densidade derivadas da resolução disponível.
final class DashboardLayoutSpec {
  const DashboardLayoutSpec._({
    required this.profile,
    required this.compact,
    required this.stretchTopRow,
    required this.useBottomRowSplit,
    required this.topRowHeroFlex,
    required this.topRowSetupFlex,
    required this.bottomRowContainmentFlex,
    required this.bottomRowChecklistFlex,
    required this.sectionGap,
    required this.columnGap,
    required this.checklistTwoColumns,
    required this.checklistPairGrid,
    required this.footerFontSize,
  });

  final DashboardLayoutProfile profile;
  final bool compact;
  final bool stretchTopRow;
  final bool useBottomRowSplit;
  final int topRowHeroFlex;
  final int topRowSetupFlex;
  final int bottomRowContainmentFlex;
  final int bottomRowChecklistFlex;
  final double sectionGap;
  final double columnGap;
  final bool checklistTwoColumns;
  final bool checklistPairGrid;
  final double footerFontSize;

  bool get isMobile => profile == DashboardLayoutProfile.mobile;
  bool get isNotebook => profile == DashboardLayoutProfile.notebook;
  bool get isDesktop => profile == DashboardLayoutProfile.desktop;

  /// Altura uniforme de cada célula na grade 2×2 do notebook.
  static double notebookCellHeight(double viewportHeight) {
    return notebookCellHeightFromAvailable(
      viewportHeight - 120,
      sectionGap: 10,
      footerReserve: 40,
    );
  }

  /// Deriva altura da célula a partir do espaço real do corpo (com [fitViewport]).
  static double notebookCellHeightFromAvailable(
    double availableHeight, {
    double sectionGap = 10,
    double footerReserve = 40,
  }) {
    final grid = availableHeight - sectionGap - footerReserve;
    return (grid / 2 * 0.9).clamp(186.0, 262.0);
  }

  /// Altura de cada linha 1×2 no desktop (hero|setup e contenção|checklist).
  /// Mesma lógica do notebook: [SizedBox] + stretch + cards com fill/expand.
  static double desktopRowHeight(double viewportHeight) {
    return (viewportHeight * 0.38).clamp(320.0, 460.0);
  }

  static DashboardLayoutSpec resolve({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final mainWidth = AppLayout.mainAreaWidth(viewportWidth);

    if (mainWidth < AppLayout.dashboardRowBreakpoint) {
      return const DashboardLayoutSpec._(
        profile: DashboardLayoutProfile.mobile,
        compact: false,
        stretchTopRow: false,
        useBottomRowSplit: false,
        topRowHeroFlex: 1,
        topRowSetupFlex: 1,
        bottomRowContainmentFlex: 1,
        bottomRowChecklistFlex: 1,
        sectionGap: 16,
        columnGap: 0,
        checklistTwoColumns: false,
        checklistPairGrid: false,
        footerFontSize: 14,
      );
    }

    if (viewportHeight < AppLayout.dashboardCompactHeightBreakpoint) {
      return const DashboardLayoutSpec._(
        profile: DashboardLayoutProfile.notebook,
        compact: true,
        stretchTopRow: false,
        useBottomRowSplit: true,
        topRowHeroFlex: 5,
        topRowSetupFlex: 5,
        bottomRowContainmentFlex: 5,
        bottomRowChecklistFlex: 5,
        sectionGap: 10,
        columnGap: 14,
        checklistTwoColumns: false,
        checklistPairGrid: true,
        footerFontSize: 14,
      );
    }

    return DashboardLayoutSpec._(
      profile: DashboardLayoutProfile.desktop,
      compact: false,
      stretchTopRow: true,
      useBottomRowSplit: true,
      // Grade 2×2 alinhada (iguais ao notebook).
      topRowHeroFlex: 5,
      topRowSetupFlex: 5,
      bottomRowContainmentFlex: 5,
      bottomRowChecklistFlex: 5,
      sectionGap: 18,
      columnGap: 20,
      checklistTwoColumns: false,
      // Mesmo visual do notebook: tiles em grade 2×2 + rodapé.
      checklistPairGrid: true,
      footerFontSize: 14,
    );
  }
}
