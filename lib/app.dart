import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_names.dart';
import 'core/theme/app_theme.dart';

class OffspringTrackerApp extends StatelessWidget {
  const OffspringTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: RouteNames.auth,
      routes: AppRoutes.routes,
    );
  }
}
