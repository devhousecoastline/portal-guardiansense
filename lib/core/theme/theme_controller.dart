import 'package:flutter/foundation.dart';
import 'package:guardian_portal/core/theme/app_palette.dart';
import 'package:guardian_portal/core/theme/portal_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de tema do portal (claro / escuro).
class ThemeController extends ChangeNotifier {
  ThemeController();

  static const _storageKey = 'portal_theme_mode';

  PortalThemeMode _mode = PortalThemeMode.dark;
  bool _ready = false;

  PortalThemeMode get mode => _mode;
  bool get ready => _ready;
  AppPalette get palette => switch (_mode) {
        PortalThemeMode.light => AppPalette.light,
        PortalThemeMode.dark => AppPalette.dark,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = PortalThemeMode.fromStorage(prefs.getString(_storageKey));
    AppColorScope.current = palette;
    _ready = true;
    notifyListeners();
  }

  Future<void> setMode(PortalThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    AppColorScope.current = palette;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }
}
