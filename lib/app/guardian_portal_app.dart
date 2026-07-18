import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_router.dart';
import 'package:guardian_portal/core/theme/app_palette.dart';
import 'package:guardian_portal/core/theme/app_theme.dart';
import 'package:guardian_portal/core/theme/theme_controller.dart';
import 'package:guardian_portal/core/theme/theme_scope.dart';
import 'package:guardian_portal/features/auth/application/auth_controller.dart';
import 'package:guardian_portal/features/auth/presentation/widgets/auth_scope.dart';

class GuardianPortalApp extends StatefulWidget {
  const GuardianPortalApp({super.key});

  @override
  State<GuardianPortalApp> createState() => _GuardianPortalAppState();
}

class _GuardianPortalAppState extends State<GuardianPortalApp> {
  late final AuthController _auth;
  late final NavigationLoadingController _navigationLoading;
  late final ThemeController _theme;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _navigationLoading = NavigationLoadingController();
    _theme = ThemeController();
    AppColorScope.current = _theme.palette;
    _router = createAppRouter(authListenable: _auth);
    _theme.load();
  }

  @override
  void dispose() {
    _auth.dispose();
    _navigationLoading.dispose();
    _theme.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: ThemeScope(
        controller: _theme,
        child: NavigationLoadingScope(
          controller: _navigationLoading,
          child: ListenableBuilder(
            listenable: _theme,
            builder: (context, _) {
              AppColorScope.current = _theme.palette;
              return MaterialApp.router(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: _theme.mode.materialThemeMode,
                locale: const Locale('pt', 'BR'),
                supportedLocales: const [Locale('pt', 'BR')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: _router,
              );
            },
          ),
        ),
      ),
    );
  }
}
