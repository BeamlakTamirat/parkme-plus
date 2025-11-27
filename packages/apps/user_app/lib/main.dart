import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared/shared.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    if (kDebugMode) print('🔧 Loading environment variables...');
    await dotenv.load(fileName: ".env");
    if (kDebugMode) print('✅ Environment variables loaded successfully');

    // Verify Chapa API keys are loaded
    final testSecretKey = dotenv.env['CHAPA_SECRET_KEY_TEST'];
    final testPublicKey = dotenv.env['CHAPA_PUBLIC_KEY_TEST'];

    if (testSecretKey != null && testSecretKey.startsWith('CHASECK_TEST-')) {
      if (kDebugMode) print('✅ Chapa Secret Key loaded: ${testSecretKey.substring(0, 20)}...');
    } else {
      if (kDebugMode) print('❌ Chapa Secret Key not found or invalid format');
      if (kDebugMode) print('🔍 Current value: $testSecretKey');
    }

    if (testPublicKey != null && testPublicKey.startsWith('CHAPUBK_TEST-')) {
      if (kDebugMode) print('✅ Chapa Public Key loaded: ${testPublicKey.substring(0, 20)}...');
    } else {
      if (kDebugMode) print('❌ Chapa Public Key not found or invalid format');
      if (kDebugMode) print('🔍 Current value: $testPublicKey');
    }
  } catch (e) {
    if (kDebugMode) print('❌ Failed to load .env file: $e');
    if (kDebugMode) print('📁 Make sure .env file exists in the root directory');
    if (kDebugMode) print('ℹ️  App will continue with default values');
  }

  // Initialize Appwrite
  try {
    if (kDebugMode) print('🚀 Initializing Appwrite...');
    await AppwriteConfig.initialize();
    if (kDebugMode) print('✅ Appwrite initialized successfully');
  } catch (e) {
    if (kDebugMode) print('❌ Appwrite initialization failed: $e');
    if (kDebugMode) print('📁 Make sure your .env file exists with correct Project ID');
    if (kDebugMode) print('ℹ️  App will continue but authentication will not work');
  }

  // Initialize Mapbox Maps
  try {
    if (kDebugMode) print('🗺️ Initializing Mapbox Maps...');
    await MapboxConfig.initialize();
    if (kDebugMode) print('✅ Mapbox Maps initialized successfully');
  } catch (e) {
    if (kDebugMode) print('❌ Mapbox Maps initialization failed: $e');
    if (kDebugMode) {
      print(
          '📁 Make sure your .env file exists with correct Mapbox access token');
    }
    if (kDebugMode) print('ℹ️  App will continue but maps will not work');
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
    child: ParkMePlusApp(),
  ));
}
