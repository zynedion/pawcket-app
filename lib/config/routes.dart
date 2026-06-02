import 'package:flutter/material.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/category_selection.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String categorySelection = '/category-selection';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        welcome: (context) => const OnboardingScreen(),
        categorySelection: (context) => const CategorySelectionScreen(),
        dashboard: (context) => const DashboardScreen(),
      };
}
