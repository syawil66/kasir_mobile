import 'package:flutter/material.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/dashboard/views/main_navigation_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    dashboard: (context) => const MainNavigationScreen(),
  };
}