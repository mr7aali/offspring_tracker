import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/offspring/presentation/screens/dashboard_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'route_names.dart';

class AppRoutes {
  const AppRoutes._();

  static Map<String, WidgetBuilder> get routes => {
    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.auth: (_) => const AuthScreen(),
    RouteNames.dashboard: (_) => const DashboardScreen(),
  };
}
