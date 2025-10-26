import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Use Supabase.instance.client directly instead of storing our own reference
  static SupabaseClient get client => Supabase.instance.client;

  // Auth helpers
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => client.auth.currentUser?.id;
  static bool get isAuthenticated => client.auth.currentUser != null;

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      print('Supabase signUp error: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Supabase signIn error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    // Sign out from Google Sign-In first (clears cached account)
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect(); // Fully disconnect to clear cache
      }
    } catch (e) {
      print('Google Sign-Out error: $e');
      // Continue with Supabase sign out even if Google sign out fails
    }

    // Then sign out from Supabase
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Google Sign-In using Supabase OAuth
  static Future<bool> signInWithGoogle() async {
    try {
      // For web, use the current origin as redirect URL
      String redirectUrl;
      if (kIsWeb) {
        // Get the current page URL for web
        redirectUrl = Uri.base.origin;
      } else {
        redirectUrl = 'http://localhost:3000'; // Fallback for mobile dev
      }

      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {
          'prompt': 'select_account', // Force account selection every time
        },
      );
      return true;
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  // Storage helpers
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    await client.storage.from(bucket).uploadBinary(
          path,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(contentType: contentType),
        );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await client.storage.from(bucket).remove([path]);
  }
}
