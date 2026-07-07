import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/core/navigation/navigation_loading_controller.dart';
import 'package:guardian_portal/core/routing/app_router.dart';
import 'package:guardian_portal/core/theme/app_theme.dart';
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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _navigationLoading = NavigationLoadingController();
    _router = createAppRouter(authListenable: _auth);
  }

  @override
  void dispose() {
    _auth.dispose();
    _navigationLoading.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: NavigationLoadingScope(
        controller: _navigationLoading,
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
