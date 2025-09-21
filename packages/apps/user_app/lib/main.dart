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
    print('🔧 Loading environment variables...');
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');

    // Verify Chapa API keys are loaded
    final testSecretKey = dotenv.env['CHAPA_SECRET_KEY_TEST'];
    final testPublicKey = dotenv.env['CHAPA_PUBLIC_KEY_TEST'];

    if (testSecretKey != null && testSecretKey.startsWith('CHASECK_TEST-')) {
      print('✅ Chapa Secret Key loaded: ${testSecretKey.substring(0, 20)}...');
    } else {
      print('❌ Chapa Secret Key not found or invalid format');
      print('🔍 Current value: $testSecretKey');
    }

    if (testPublicKey != null && testPublicKey.startsWith('CHAPUBK_TEST-')) {
      print('✅ Chapa Public Key loaded: ${testPublicKey.substring(0, 20)}...');
    } else {
      print('❌ Chapa Public Key not found or invalid format');
      print('🔍 Current value: $testPublicKey');
    }
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    print('📁 Make sure .env file exists in the root directory');
    print('ℹ️  App will continue with default values');
  }

  // Initialize Appwrite
  try {
    print('🚀 Initializing Appwrite...');
    await AppwriteConfig.initialize();
    print('✅ Appwrite initialized successfully');
  } catch (e) {
    print('❌ Appwrite initialization failed: $e');
    print('📁 Make sure your .env file exists with correct Project ID');
    print('ℹ️  App will continue but authentication will not work');
  }

  // Initialize Mapbox Maps
  try {
    print('🗺️ Initializing Mapbox Maps...');
    await MapboxConfig.initialize();
    print('✅ Mapbox Maps initialized successfully');
  } catch (e) {
    print('❌ Mapbox Maps initialization failed: $e');
    print(
        '📁 Make sure your .env file exists with correct Mapbox access token');
    print('ℹ️  App will continue but maps will not work');
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
    child: WeParkApp(),
  ));
}
