import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/enhanced_sign_in_screen.dart';
import '../screens/auth/enhanced_sign_up_screen.dart';
import '../screens/home/comprehensive_home_screen.dart';
import '../screens/parking/find_parking_screen.dart';
import '../screens/history/parking_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/booking/active_booking_screen.dart';

import '../screens/payment/enhanced_payment_screen.dart';
import '../screens/maps/maps_screen.dart';
import '../screens/navigation/navigation_screen.dart';
import '../screens/debug/database_debug_screen.dart';

/// Comprehensive router provider
final comprehensiveRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Welcome
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Authentication routes
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const EnhancedSignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'sign-up',
        builder: (context, state) => const EnhancedSignUpScreen(),
      ),

      // Home route
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const ComprehensiveHomeScreen(),
      ),

      // Find Parking route
      GoRoute(
        path: '/find-parking',
        name: 'find-parking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FindParkingScreen(extraData: extra);
        },
      ),

      // Bookings route
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const ParkingHistoryScreen(),
      ),

      // Booking route
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ActiveBookingScreen(bookingData: extra);
        },
      ),

      // Profile route
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Payment route
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EnhancedPaymentScreen(
            bookingData: extra ?? {},
          );
        },
      ),

      // Maps route
      GoRoute(
        path: '/maps',
        name: 'maps',
        builder: (context, state) => const MapsScreen(),
      ),

      // Navigation route
      GoRoute(
        path: '/navigation',
        name: 'navigation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NavigationScreen(navigationData: extra);
        },
      ),

      // Debug route (for development)
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DatabaseDebugScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Splash'),
            ),
          ],
        ),
      ),
    ),
  );
});
