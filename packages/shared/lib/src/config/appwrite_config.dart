import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple Appwrite configuration - just what we need
class AppwriteConfig {
  static Client? _client;
  static Account? _account;
  static Databases? _databases;
  static bool _isInitialized = false;

  // Simple configuration
  static String get endpoint =>
      dotenv.env['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1';
  static String get projectId => dotenv.env['APPWRITE_PROJECT_ID'] ?? '';

  /// Initialize Appwrite - super simple
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      if (kDebugMode) print('📁 Loading .env file...');
      await dotenv.load(fileName: ".env");

      if (kDebugMode) print('📋 Environment loaded. Checking Project ID...');
      if (kDebugMode)
        print(
            '🔑 Found Project ID: ${dotenv.env['APPWRITE_PROJECT_ID'] ?? 'NOT FOUND'}');

      if (projectId.isEmpty) {
        throw Exception('APPWRITE_PROJECT_ID not found in .env file');
      }

      // Create client
      _client = Client()
        ..setEndpoint(endpoint)
        ..setProject(projectId);

      // Initialize services
      _account = Account(_client!);
      _databases = Databases(_client!);

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Appwrite initialized successfully');
        print('📡 Endpoint: $endpoint');
        print('🆔 Project: $projectId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Appwrite initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Get Appwrite services
  static Client get client {
    if (_client == null) throw Exception('Appwrite not initialized');
    return _client!;
  }

  static Account get account {
    if (_account == null) throw Exception('Appwrite not initialized');
    return _account!;
  }

  static Databases get databases {
    if (_databases == null) throw Exception('Appwrite not initialized');
    return _databases!;
  }

  static bool get isInitialized => _isInitialized;
}
