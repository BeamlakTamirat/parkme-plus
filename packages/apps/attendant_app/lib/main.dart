import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite
  try {
    if (kDebugMode) print('🚀 Initializing Appwrite for Attendant App...');
    await AppwriteConfig.initialize();
    if (kDebugMode) print('✅ Appwrite initialized successfully');
  } catch (e) {
    if (kDebugMode) print('❌ Appwrite initialization failed: $e');
    if (kDebugMode) print('📁 Make sure your .env file exists with correct Project ID');
    if (kDebugMode) print('ℹ️  App will continue but authentication will not work');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(
    child: AttendantApp(),
  ));
}
