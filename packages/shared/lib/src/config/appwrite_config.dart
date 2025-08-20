import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Appwrite configuration for WePark
class AppwriteConfig {
  static Client? _client;
  static Account? _account;
  static Databases? _databases;
  static bool _isInitialized = false;

  // Getters for Appwrite services
  static Client get client {
    if (_client == null) {
      throw Exception('Appwrite not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Account get account {
    if (_account == null) {
      throw Exception('Appwrite not initialized. Call initialize() first.');
    }
    return _account!;
  }

  static Databases get databases {
    if (_databases == null) {
      throw Exception('Appwrite not initialized. Call initialize() first.');
    }
    return _databases!;
  }

  // Environment variables
  static String get endpoint {
    final envEndpoint = dotenv.env['APPWRITE_ENDPOINT'];
    if (envEndpoint != null && envEndpoint.isNotEmpty) {
      return envEndpoint;
    }
    // Fallback to cloud endpoint
    return 'https://cloud.appwrite.io/v1';
  }

  static String get projectId {
    final projectId = dotenv.env['APPWRITE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw Exception('APPWRITE_PROJECT_ID not found in .env file');
    }
    return projectId;
  }

  /// Initialize Appwrite client
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) print('🚀 Initializing Appwrite...');

      // Load environment variables
      if (kDebugMode) print('📁 Loading .env file...');
      await dotenv.load(fileName: ".env");

      if (kDebugMode) {
        print('📋 Environment loaded successfully');
        print(
            '🔑 Project ID: ${dotenv.env['APPWRITE_PROJECT_ID'] ?? 'NOT FOUND'}');
        print('🌐 Endpoint: $endpoint');
      }

      // Validate project ID
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

      // Test connection
      await _testConnection();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Appwrite initialization failed: $e');
        print('🔍 Troubleshooting tips:');
        print('   1. Check your internet connection');
        print('   2. Verify APPWRITE_PROJECT_ID in .env file');
        print('   3. Check if Appwrite endpoint is correct');
        print('   4. Ensure .env file is in the correct location');
      }
      rethrow;
    }
  }

  /// Test connection to Appwrite
  static Future<void> _testConnection() async {
    try {
      if (kDebugMode) print('🔍 Testing Appwrite connection...');

      // Try to get account info to test connection
      await _account!.get();

      if (kDebugMode) print('✅ Appwrite connection test successful');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Appwrite connection test failed: $e');
        print('🌐 Current endpoint: $endpoint');
        print('🆔 Current project ID: $projectId');
      }
      // Don't throw here, just log the error
      if (kDebugMode) print('⚠️ Connection test failed, but continuing...');
    }
  }

  /// Check if Appwrite is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization (for testing)
  static void reset() {
    _client = null;
    _account = null;
    _databases = null;
    _isInitialized = false;
  }
}
