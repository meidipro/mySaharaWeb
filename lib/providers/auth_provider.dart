import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  /// Current user
  UserModel? get user => _user;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }

      _setError('Failed to create account');
      return false;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }

      _setError('Invalid email or password');
      return false;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  /// Load user profile
  Future<void> loadUserProfile() async {
    if (!isAuthenticated) return;

    _setLoading(true);
    _clearError();

    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _authService.getUserProfile(userId);
        if (user != null) {
          _user = user;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.updateUserProfile(updatedUser);
      if (success) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }

      _setError('Failed to update profile');
      return false;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user name
  Future<bool> updateUserName(String fullName) async {
    if (_user == null) return false;

    final updatedUser = UserModel(
      id: _user!.id,
      email: _user!.email,
      fullName: fullName,
      phoneNumber: _user!.phoneNumber,
      dateOfBirth: _user!.dateOfBirth,
      gender: _user!.gender,
      bloodGroup: _user!.bloodGroup,
      profileImageUrl: _user!.profileImageUrl,
      createdAt: _user!.createdAt,
      updatedAt: DateTime.now(),
    );

    return await updateProfile(updatedUser);
  }

  /// Update user phone number
  Future<bool> updatePhoneNumber(String phoneNumber) async {
    if (_user == null) return false;

    final updatedUser = UserModel(
      id: _user!.id,
      email: _user!.email,
      fullName: _user!.fullName,
      phoneNumber: phoneNumber,
      dateOfBirth: _user!.dateOfBirth,
      gender: _user!.gender,
      bloodGroup: _user!.bloodGroup,
      profileImageUrl: _user!.profileImageUrl,
      createdAt: _user!.createdAt,
      updatedAt: DateTime.now(),
    );

    return await updateProfile(updatedUser);
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google using Supabase OAuth
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithGoogle();
      // OAuth will redirect, so we don't wait for response
      return true;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Parse error message from exception
  String _parseErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    if (error.startsWith('Exception: ')) {
      error = error.substring(11);
    }

    // Parse common Supabase error messages
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please verify your email address';
    } else if (error.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters';
    } else if (error.contains('Unable to validate email address')) {
      return 'Please enter a valid email address';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (error.contains('over_email_send_rate_limit') || error.contains('429')) {
      return 'Too many attempts. Please wait a minute and try again.';
    } else if (error.contains('verify your email')) {
      return 'Please verify your email address first. Check your inbox for the verification link.';
    } else if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Authentication error. Please check your credentials.';
    } else if (error.contains('Email rate limit exceeded')) {
      return 'Please wait before requesting another email.';
    }

    return error;
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    if (_user == null) return false;

    return _user!.fullName?.isNotEmpty == true &&
        _user!.dateOfBirth != null &&
        _user!.gender != null &&
        _user!.bloodGroup != null;
  }

  /// Get user initials for avatar
  String getUserInitials() {
    if (_user == null || _user!.fullName?.isEmpty != false) return '?';

    final parts = _user!.fullName!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Get user age
  int? getUserAge() {
    if (_user?.dateOfBirth == null) return null;

    final now = DateTime.now();
    final birthDateString = _user!.dateOfBirth!;

    // Parse date string to DateTime
    try {
      final birthDate = DateTime.parse(birthDateString);
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }
}
