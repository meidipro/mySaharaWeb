import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_member.dart';
import '../services/family_service.dart';

/// Provider for managing family members and invites state
class FamilyProvider with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  List<FamilyMember> _familyMembers = [];
  List<FamilyMemberWithProfile> _familyMembersWithProfile = [];
  List<FamilyInvite> _familyInvites = [];
  Map<String, dynamic>? _healthSummary;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FamilyMember> get familyMembers => _familyMembers;
  List<FamilyMemberWithProfile> get familyMembersWithProfile => _familyMembersWithProfile;
  List<FamilyInvite> get familyInvites => _familyInvites;
  Map<String, dynamic>? get healthSummary => _healthSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Load all family members
  Future<void> loadFamilyMembers() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _familyMembers = await _familyService.getFamilyMembers(_currentUserId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading family members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load family members with their health profile data
  Future<void> loadFamilyMembersWithProfile() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _familyMembersWithProfile = await _familyService.getFamilyMembersWithProfile(_currentUserId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading family members with profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load family invites
  Future<void> loadFamilyInvites() async {
    if (_currentUserId == null) return;

    try {
      _familyInvites = await _familyService.getFamilyInvites(_currentUserId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading family invites: $e');
      notifyListeners();
    }
  }

  /// Load health summary
  Future<void> loadHealthSummary() async {
    if (_currentUserId == null) return;

    try {
      _healthSummary = await _familyService.getFamilyHealthSummary(_currentUserId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading health summary: $e');
      notifyListeners();
    }
  }

  /// Add a new family member
  Future<bool> addFamilyMember(FamilyMember member) async {
    if (_currentUserId == null) return false;

    try {
      final newMember = await _familyService.addFamilyMember(member);
      _familyMembers.insert(0, newMember);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error adding family member: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update a family member
  Future<bool> updateFamilyMember(FamilyMember member) async {
    try {
      final updatedMember = await _familyService.updateFamilyMember(member);
      final index = _familyMembers.indexWhere((m) => m.id == updatedMember.id);
      if (index != -1) {
        _familyMembers[index] = updatedMember;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error updating family member: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a family member
  Future<bool> deleteFamilyMember(String id) async {
    try {
      await _familyService.deleteFamilyMember(id);
      _familyMembers.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error deleting family member: $e');
      notifyListeners();
      return false;
    }
  }

  /// Create a new family invite
  Future<FamilyInvite?> createFamilyInvite({
    String? relationship,
    int expiryHours = 48,
  }) async {
    if (_currentUserId == null) return null;

    try {
      final invite = await _familyService.createFamilyInvite(
        userId: _currentUserId!,
        relationship: relationship,
        expiryHours: expiryHours,
      );
      if (invite != null) {
        _familyInvites.insert(0, invite);
        notifyListeners();
      }
      return invite;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error creating family invite: $e');
      notifyListeners();
      return null;
    }
  }

  /// Redeem an invite code
  Future<Map<String, dynamic>?> redeemInviteCode(String code) async {
    if (_currentUserId == null) return null;

    try {
      final userResponse = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', _currentUserId!)
          .single();

      final result = await _familyService.redeemInviteCode(
        code: code,
        redeemingUserId: _currentUserId!,
        redeemingUserName: userResponse['full_name'] as String,
      );

      // Reload family members after successful redemption
      await loadFamilyMembers();

      return result;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error redeeming invite code: $e');
      notifyListeners();
      return null;
    }
  }

  /// Delete a family invite
  Future<bool> deleteFamilyInvite(String id) async {
    try {
      await _familyService.deleteFamilyInvite(id);
      _familyInvites.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error deleting family invite: $e');
      notifyListeners();
      return false;
    }
  }

  /// Get a single family member by ID
  Future<FamilyMember?> getFamilyMemberById(String id) async {
    try {
      return await _familyService.getFamilyMemberById(id);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error getting family member: $e');
      return null;
    }
  }

  /// Get pending invites (not used and not expired)
  Future<List<FamilyInvite>> getPendingInvites() async {
    if (_currentUserId == null) return [];

    try {
      return await _familyService.getPendingInvites(_currentUserId!);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error getting pending invites: $e');
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all family data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadFamilyMembers(),
      loadFamilyInvites(),
      loadHealthSummary(),
    ]);
  }
}
