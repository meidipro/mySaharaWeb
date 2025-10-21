import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseKey => dotenv.env['SUPABASE_KEY'] ?? '';

  // AI Services
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Backend URL
  static String get backendUrl {
    final fromEnv = dotenv.env['BACKEND_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      // For web, assume same host different port if running locally
      return 'http://localhost:8000';
    }

    // Mobile/Desktop heuristics
    try {
      if (Platform.isAndroid) {
        // Android emulator maps host loopback to 10.0.2.2
        return 'http://10.0.2.2:8000';
      }
      if (Platform.isIOS) {
        return 'http://127.0.0.1:8000';
      }
      // Windows/macOS/Linux desktop
      return 'http://127.0.0.1:8000';
    } catch (_) {
      // Fallback
      return 'http://localhost:8000';
    }
  }

  // Web Viewer URL for QR code sharing
  static String get webViewerUrl {
    final fromEnv = dotenv.env['WEB_VIEWER_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:3000'; // Fallback for local development
  }

  // App Constants
  static const String appName = 'mySahara';
  static const String appVersion = '1.0.0';
}
