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
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Wait for the database trigger to create the user profile
        await Future.delayed(const Duration(milliseconds: 800));

        // Update the profile with full_name (trigger only sets id and email)
        // Use upsert to handle the case where the profile might not exist yet
        await SupabaseService.client.from('users').upsert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');

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
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserModel.fromJson(response);
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
