import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/comprehensive_app_router.dart';
import 'providers/comprehensive_providers.dart';
import 'package:shared/shared.dart';

class ParkMePlusApp extends ConsumerStatefulWidget {
  const ParkMePlusApp({super.key});

  @override
  ConsumerState<ParkMePlusApp> createState() => _ParkMePlusAppState();
}

class _ParkMePlusAppState extends ConsumerState<ParkMePlusApp> {
  @override
  void initState() {
    super.initState();
    // Set up auth state callback
    final authService = ComprehensiveAuthService.instance;
    authService.setAuthStateCallback(() {
      // Trigger auth state change to refresh providers
      ref.read(authStateProvider.notifier).state =
          DateTime.now().toIso8601String();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(comprehensiveRouterProvider);

    return MaterialApp.router(
      title: 'ParkMe+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        fontFamily: 'SF Pro Display',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
