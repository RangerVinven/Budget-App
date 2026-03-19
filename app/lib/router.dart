import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_budget_screen.dart';
import 'screens/budget_detail_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboardShell');
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'settingsShell');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorDashboardKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'create-budget',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CreateBudgetScreen(),
                ),
                GoRoute(
                  path: 'budget',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const BudgetDetailScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettingsKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);