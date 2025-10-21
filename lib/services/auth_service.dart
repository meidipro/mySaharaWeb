import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Sign up new user
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Pass full_name in metadata so the trigger can use it
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Database trigger automatically creates the user profile with full_name from metadata
        // Wait for it to complete
        await Future.delayed(const Duration(milliseconds: 1000));

        // If email confirmation is required, user won't have a session yet
        // Return a basic user model without fetching from database
        if (response.session == null) {
          // Email confirmation required - return basic info
          return UserModel(
            id: response.user!.id,
            email: email,
            fullName: fullName,
            createdAt: DateTime.now(),
          );
        }

        // User has a session, fetch full profile
        return await getUserProfile(response.user!.id);
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in existing user
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if email is confirmed
        if (response.user!.emailConfirmedAt == null) {
          throw Exception('Please verify your email before signing in. Check your inbox for the verification link.');
        }

        return await getUserProfile(response.user!.id);
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await SupabaseService.signOut();
    await _storage.deleteAll();
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      // Add retry logic for cases where trigger hasn't completed yet
      for (int i = 0; i < 3; i++) {
        final response = await SupabaseService.client
            .from('users')
            .select('*')
            .eq('id', userId)
            .maybeSingle();

        if (response != null) {
          return UserModel.fromJson(response);
        }

        // Wait before retrying
        if (i < 2) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }

      print('User profile not found after retries for userId: $userId');
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      await SupabaseService.client.from('users').update(user.toJson()).eq('id', user.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    await SupabaseService.resetPassword(email);
  }

  // Google Sign-In using Supabase OAuth
  Future<bool> signInWithGoogle() async {
    try {
      await SupabaseService.signInWithGoogle();
      return true;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Check if authenticated
  bool get isAuthenticated => SupabaseService.isAuthenticated;

  // Get current user
  User? get currentUser => SupabaseService.currentUser;

  // Get current user ID
  String? get currentUserId => SupabaseService.currentUserId;

  // Get current user JWT
  Future<String?> getToken() async {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }
}
