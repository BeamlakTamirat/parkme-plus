import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/simple_sign_in_screen.dart';
import '../screens/auth/simple_sign_up_screen.dart';
import '../screens/home/simple_home_screen.dart';
import '../providers/simple_providers.dart';

/// Simple router provider
final simpleRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    routes: [
      // Authentication routes
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SimpleSignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'sign-up',
        builder: (context, state) => const SimpleSignUpScreen(),
      ),

      // Home route
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const SimpleHomeScreen(),
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
              onPressed: () => context.go('/sign-in'),
              child: const Text('Go to Sign In'),
            ),
          ],
        ),
      ),
    ),
  );
});
