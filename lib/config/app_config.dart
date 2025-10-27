import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Backend URL - Production backend on Render
  static String get backendUrl {
    // Use compile-time environment variable for web
    const envBackendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'https://mysahara.onrender.com',
    );

    if (kIsWeb) {
      return envBackendUrl;
    }

    // For mobile/desktop, also use the production backend
    return envBackendUrl;
  }

  // Web Viewer URL for QR code sharing
  static String get webViewerUrl => const String.fromEnvironment(
        'WEB_VIEWER_URL',
        defaultValue: 'https://my-sahara-web-view-n6wh.vercel.app',
      );

  // App Constants
  static const String appName = 'mySahara';
  static const String appVersion = '1.0.0';
}
