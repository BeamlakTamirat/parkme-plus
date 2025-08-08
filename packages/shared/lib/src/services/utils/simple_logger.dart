import 'package:flutter/foundation.dart';

/// Simple logging service that works without external dependencies
class SimpleLogger {
  static SimpleLogger? _instance;

  SimpleLogger._internal();

  static SimpleLogger get instance {
    _instance ??= SimpleLogger._internal();
    return _instance!;
  }

  /// Log debug message
  void debug(String message) {
    if (kDebugMode) {
      print('🐛 [DEBUG] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  /// Log info message
  void info(String message) {
    if (kDebugMode) {
      print('ℹ️ [INFO] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  /// Log warning message
  void warning(String message) {
    if (kDebugMode) {
      print('⚠️ [WARNING] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  /// Log error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ [ERROR] ${DateTime.now().toIso8601String()}: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Log fatal message
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    print('💀 [FATAL] ${DateTime.now().toIso8601String()}: $message');
    if (error != null) {
      print('Error details: $error');
    }
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}

// Global logger instance for easy access
final logger = SimpleLogger.instance;
