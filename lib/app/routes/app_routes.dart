import 'package:flutter/material.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/dashboard/views/main_navigation_screen.dart';
import '../../features/inventory/views/inventory_screen.dart';
import '../../features/pos/views/pos_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String pos = '/pos';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    dashboard: (context) => const MainNavigationScreen(),
    inventory: (context) => const InventoryScreen(),
    pos: (context) => PosScreen(),
  };
}
