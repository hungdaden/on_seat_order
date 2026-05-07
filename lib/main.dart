import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/order_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/orders_screen.dart';
import 'screens/admin/menu_management_screen.dart';
import 'screens/admin/stats_screen.dart';
import 'screens/display_screen.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(const PhoSaigonApp());
}

class PhoSaigonApp extends StatelessWidget {
  const PhoSaigonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Phở Cẩm Phả',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Home page
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    // Order page (customer)
    GoRoute(
      path: '/order',
      builder: (context, state) {
        final table =
            int.tryParse(state.uri.queryParameters['table'] ?? '1') ?? 1;
        return OrderScreen(tableNumber: table);
      },
    ),

    // Admin login
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminLoginScreen(),
    ),

    // Admin shell with nested routes
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/admin/menu',
          builder: (context, state) => const MenuManagementScreen(),
        ),
        GoRoute(
          path: '/admin/stats',
          builder: (context, state) => const StatsScreen(),
        ),
      ],
    ),

    // Display screen (TV)
    GoRoute(
      path: '/display',
      builder: (context, state) => const DisplayScreen(),
    ),
  ],
);
