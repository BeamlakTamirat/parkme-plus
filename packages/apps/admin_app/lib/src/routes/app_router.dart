import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/users/users_management_screen.dart';
import '../screens/locations/locations_management_screen.dart';
import '../screens/bookings/bookings_overview_screen.dart';
import '../screens/analytics/analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuthenticated =
          await ref.read(isAdminAuthenticatedProvider.future);

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && state.fullPath != '/login') {
        return '/login';
      }

      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && state.fullPath == '/login') {
        return '/dashboard';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => const UsersManagementScreen(),
      ),
      GoRoute(
        path: '/locations',
        name: 'locations',
        builder: (context, state) => const LocationsManagementScreen(),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingsOverviewScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.fullPath}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
