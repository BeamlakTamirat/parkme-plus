import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../providers/attendant_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/scanner/qr_scanner_screen.dart';
import '../screens/bookings/booking_details_screen.dart';
import '../screens/spots/spot_management_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuthenticated =
          await ref.read(isAttendantAuthenticatedProvider.future);

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
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'booking-details',
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          final booking = state.extra as Booking?;
          return BookingDetailsScreen(
            bookingId: bookingId,
            booking: booking,
          );
        },
      ),
      GoRoute(
        path: '/spots',
        name: 'spot-management',
        builder: (context, state) => const SpotManagementScreen(),
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
