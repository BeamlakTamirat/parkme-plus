import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite
  try {
    print('🚀 Initializing Appwrite for Admin App...');
    await AppwriteConfig.initialize();
    print('✅ Appwrite initialized successfully');
  } catch (e) {
    print('❌ Appwrite initialization failed: $e');
    print('📁 Make sure your .env file exists with correct Project ID');
    print('ℹ️  App will continue but authentication will not work');
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
    child: AdminApp(),
  ));
}
