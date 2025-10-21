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
        // Create user profile
        await SupabaseService.client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });

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
