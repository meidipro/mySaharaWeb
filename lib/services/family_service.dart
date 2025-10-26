import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_member.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Service for managing family members and connections
/// Handles family member CRUD, connection code generation, and linking
class FamilyService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get current user's family code
  Future<String?> getMyFamilyCode() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('users')
          .select('family_code')
          .eq('id', userId)
          .single();

      return response['family_code'] as String?;
    } catch (e) {
      print('Error getting family code: $e');
      return null;
    }
  }

  /// Get user profile by family code
  Future<UserProfile?> getUserByFamilyCode(String familyCode) async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('family_code', familyCode.toUpperCase())
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error finding user by family code: $e');
      return null;
    }
  }

  /// Connect with a family member using their family code
  Future<Map<String, dynamic>> connectWithFamilyCode({
    required String familyCode,
    required String relationship,
    required String currentUserId,
  }) async {
    try {
      // Find the user with this family code
      final targetUser = await getUserByFamilyCode(familyCode);

      if (targetUser == null) {
        throw Exception('Invalid family code. No user found with code: $familyCode');
      }

      // Check if user is trying to connect with themselves
      if (targetUser.id == currentUserId) {
        throw Exception('You cannot add yourself as a family member');
      }

      // Check if already connected
      final existing = await _client
          .from('family_members')
          .select()
          .eq('user_id', currentUserId)
          .eq('linked_user_id', targetUser.id)
          .maybeSingle();

      if (existing != null) {
        throw Exception('${targetUser.fullName ?? "This user"} is already in your family list');
      }

      // Create family member entry for current user
      final memberForCurrentUser = await addFamilyMember(FamilyMember(
        userId: currentUserId,
        linkedUserId: targetUser.id,
        fullName: targetUser.fullName ?? targetUser.email,
        relationship: relationship,
        gender: targetUser.gender, // Can be null - that's OK
        bloodGroup: targetUser.bloodGroup,
        chronicDiseases: targetUser.chronicDiseases,
        allergies: targetUser.allergies,
        createdAt: DateTime.now(),
      ));

      // Create reciprocal family member entry for target user
      final currentUserProfile = await _client
          .from('users')
          .select('*')
          .eq('id', currentUserId)
          .single();

      final currentUserData = UserProfile.fromJson(currentUserProfile);

      final memberForTargetUser = await addFamilyMember(FamilyMember(
        userId: targetUser.id,
        linkedUserId: currentUserId,
        fullName: currentUserData.fullName ?? currentUserData.email,
        relationship: _getReciprocalRelationship(relationship),
        gender: currentUserData.gender,
        bloodGroup: currentUserData.bloodGroup,
        chronicDiseases: currentUserData.chronicDiseases,
        allergies: currentUserData.allergies,
        createdAt: DateTime.now(),
      ));

      return {
        'success': true,
        'member': memberForCurrentUser,
        'targetUser': targetUser,
      };
    } catch (e) {
      print('Error connecting with family code: $e');
      rethrow;
    }
  }

  /// Get all family members for a user
  Future<List<FamilyMember>> getFamilyMembers(String userId) async {
    try {
      final response = await _client
          .from('family_members')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FamilyMember.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch family members: $e');
    }
  }

  /// Get a single family member by ID
  Future<FamilyMember?> getFamilyMemberById(String id) async {
    try {
      final response = await _client
          .from('family_members')
          .select()
          .eq('id', id)
          .single();

      return FamilyMember.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Add a new family member
  Future<FamilyMember> addFamilyMember(FamilyMember member) async {
    try {
      final response = await _client
          .from('family_members')
          .insert(member.toJson())
          .select()
          .single();

      return FamilyMember.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add family member: $e');
    }
  }

  /// Update a family member
  Future<FamilyMember> updateFamilyMember(FamilyMember member) async {
    try {
      final response = await _client
          .from('family_members')
          .update(member.toJson())
          .eq('id', member.id!)
          .select()
          .single();

      return FamilyMember.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update family member: $e');
    }
  }

  /// Delete a family member
  Future<void> deleteFamilyMember(String id) async {
    try {
      await _client.from('family_members').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete family member: $e');
    }
  }

  /// Generate a unique 6-digit invite code
  String generateInviteCode() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    return code;
  }

  /// Create a family invite code
  Future<FamilyInvite?> createFamilyInvite({
    required String userId,
    String? relationship,
    int expiryHours = 48,
  }) async {
    try {
      final inviteCode = generateInviteCode();
      final expiresAt = DateTime.now().add(Duration(hours: expiryHours));

      final response = await _client
          .from('family_invites')
          .insert({
            'user_id': userId,
            'invite_code': inviteCode,
            'relationship': relationship,
            'expires_at': expiresAt.toIso8601String(),
            'is_used': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return FamilyInvite.fromJson(response);
    } catch (e) {
      // If table doesn't exist, return null
      print('Error creating family invite: $e');
      return null;
    }
  }

  /// Redeem an invite code to connect with another user
  Future<Map<String, dynamic>> redeemInviteCode({
    required String code,
    required String redeemingUserId,
    required String redeemingUserName,
  }) async {
    try {
      // Find the invite by code
      final inviteResponse = await _client
          .from('family_invites')
          .select()
          .eq('invite_code', code)
          .eq('is_used', false)
          .maybeSingle();

      if (inviteResponse == null) {
        throw Exception('Invalid or expired invite code');
      }

      final invite = FamilyInvite.fromJson(inviteResponse);

      // Check if invite is expired
      if (invite.expiresAt.isBefore(DateTime.now())) {
        throw Exception('This invite code has expired');
      }

      // Check if user is trying to redeem their own code
      if (invite.userId == redeemingUserId) {
        throw Exception('You cannot redeem your own invite code');
      }

      // Mark the invite as used
      await _client
          .from('family_invites')
          .update({
            'is_used': true,
            'used_by': redeemingUserId,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invite.id!);

      // Get the inviter's information
      final inviterResponse = await _client
          .from('users')
          .select('id, full_name, email')
          .eq('id', invite.userId)
          .single();

      // Create family member entry for the inviter in redeeming user's account
      final inviterMember = await addFamilyMember(FamilyMember(
        userId: redeemingUserId,
        linkedUserId: invite.userId,
        fullName: inviterResponse['full_name'] as String,
        relationship: invite.relationship ?? 'Family',
        createdAt: DateTime.now(),
      ));

      // Create family member entry for the redeeming user in inviter's account
      final redeemingUserResponse = await _client
          .from('users')
          .select('full_name')
          .eq('id', redeemingUserId)
          .single();

      final redeemingMember = await addFamilyMember(FamilyMember(
        userId: invite.userId,
        linkedUserId: redeemingUserId,
        fullName: redeemingUserResponse['full_name'] as String,
        relationship: _getReciprocalRelationship(invite.relationship),
        createdAt: DateTime.now(),
      ));

      return {
        'success': true,
        'inviter': inviterResponse,
        'connection': inviterMember,
      };
    } catch (e) {
      // If table doesn't exist or other errors, provide specific error message
      print('Error redeeming invite code: $e');
      if (e.toString().contains('family_invites')) {
        throw Exception('Invite feature is not available');
      }
      throw Exception('Failed to redeem invite code: $e');
    }
  }

  /// Get reciprocal relationship (e.g., parent -> child, sibling -> sibling)
  String _getReciprocalRelationship(String? relationship) {
    if (relationship == null) return 'Family';

    switch (relationship.toLowerCase()) {
      case 'parent':
      case 'father':
      case 'mother':
        return 'Child';
      case 'child':
      case 'son':
      case 'daughter':
        return 'Parent';
      case 'sibling':
      case 'brother':
      case 'sister':
        return 'Sibling';
      case 'spouse':
      case 'husband':
      case 'wife':
        return 'Spouse';
      case 'grandparent':
      case 'grandfather':
      case 'grandmother':
        return 'Grandchild';
      case 'grandchild':
      case 'grandson':
      case 'granddaughter':
        return 'Grandparent';
      default:
        return 'Family';
    }
  }

  /// Get all family invites created by a user
  Future<List<FamilyInvite>> getFamilyInvites(String userId) async {
    try {
      final response = await _client
          .from('family_invites')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FamilyInvite.fromJson(json))
          .toList();
    } catch (e) {
      // If table doesn't exist, return empty list
      print('Error loading family invites: $e');
      return [];
    }
  }

  /// Get pending (unused and not expired) invites for a user
  Future<List<FamilyInvite>> getPendingInvites(String userId) async {
    try {
      final response = await _client
          .from('family_invites')
          .select()
          .eq('user_id', userId)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FamilyInvite.fromJson(json))
          .toList();
    } catch (e) {
      // If table doesn't exist, return empty list
      print('Error loading pending invites: $e');
      return [];
    }
  }

  /// Delete a family invite
  Future<void> deleteFamilyInvite(String id) async {
    try {
      await _client.from('family_invites').delete().eq('id', id);
    } catch (e) {
      // If table doesn't exist, just log the error
      print('Error deleting family invite: $e');
    }
  }

  /// Link a family member to an existing app user
  Future<FamilyMember> linkFamilyMemberToUser({
    required String familyMemberId,
    required String linkedUserId,
  }) async {
    try {
      final response = await _client
          .from('family_members')
          .update({'linked_user_id': linkedUserId})
          .eq('id', familyMemberId)
          .select()
          .single();

      return FamilyMember.fromJson(response);
    } catch (e) {
      throw Exception('Failed to link family member: $e');
    }
  }

  /// Get health summary for all family members
  Future<Map<String, dynamic>> getFamilyHealthSummary(String userId) async {
    try {
      final members = await getFamilyMembers(userId);

      int totalMembers = members.length;
      int membersWithChronicDiseases = members.where((m) =>
        m.chronicDiseases != null && m.chronicDiseases!.isNotEmpty
      ).length;
      int membersOnMedication = members.where((m) =>
        m.medications != null && m.medications!.isNotEmpty
      ).length;
      int membersWithAllergies = members.where((m) =>
        m.allergies != null && m.allergies!.isNotEmpty
      ).length;

      return {
        'total_members': totalMembers,
        'members_with_chronic_diseases': membersWithChronicDiseases,
        'members_on_medication': membersOnMedication,
        'members_with_allergies': membersWithAllergies,
      };
    } catch (e) {
      throw Exception('Failed to generate family health summary: $e');
    }
  }

  /// Get family chronic diseases summary
  Future<Map<String, dynamic>> getFamilyChronicDiseases(String userId) async {
    try {
      final members = await getFamilyMembers(userId);

      final Map<String, List<String>> diseasesByMember = {};
      final Set<String> allDiseases = {};

      for (final member in members) {
        if (member.chronicDiseases != null && member.chronicDiseases!.isNotEmpty) {
          final diseases = member.chronicDiseases!
              .split(',')
              .map((d) => d.trim())
              .where((d) => d.isNotEmpty)
              .toList();

          diseasesByMember[member.fullName] = diseases;
          allDiseases.addAll(diseases);
        }
      }

      return {
        'total_diseases': allDiseases.length,
        'diseases_by_member': diseasesByMember,
        'all_diseases': allDiseases.toList(),
        'affected_members': diseasesByMember.length,
      };
    } catch (e) {
      throw Exception('Failed to get family chronic diseases: $e');
    }
  }

  /// Get family members with their health profile data
  Future<List<FamilyMemberWithProfile>> getFamilyMembersWithProfile(String userId) async {
    try {
      final members = await getFamilyMembers(userId);
      final List<FamilyMemberWithProfile> membersWithProfile = [];

      for (final member in members) {
        String? email;
        int documentCount = 0;
        int timelineEventCount = 0;
        List<String>? recentDiseases;

        // If family member has a linked user account, fetch their data
        if (member.linkedUserId != null && member.linkedUserId!.isNotEmpty) {
          try {
            // Get user email
            final userResponse = await _client
                .from('users')
                .select('email')
                .eq('id', member.linkedUserId!)
                .maybeSingle();

            if (userResponse != null) {
              email = userResponse['email'] as String?;
            }

            // Get document count
            final documentResponse = await _client
                .from('medical_documents')
                .select('id')
                .eq('user_id', member.linkedUserId!);

            documentCount = (documentResponse as List).length;

            // Get timeline event count
            final timelineResponse = await _client
                .from('medical_history')
                .select('id')
                .eq('user_id', member.linkedUserId!);

            timelineEventCount = (timelineResponse as List).length;

            // Get recent diseases from timeline
            final recentEventsResponse = await _client
                .from('medical_history')
                .select('disease')
                .eq('user_id', member.linkedUserId!)
                .not('disease', 'is', null)
                .order('event_date', ascending: false)
                .limit(5);

            if (recentEventsResponse is List && recentEventsResponse.isNotEmpty) {
              recentDiseases = recentEventsResponse
                  .map((e) => e['disease'] as String?)
                  .where((d) => d != null && d.isNotEmpty)
                  .cast<String>()
                  .toList();
            }
          } catch (e) {
            // If there's an error fetching profile data, just skip it
            print('Error fetching profile data for ${member.fullName}: $e');
          }
        }

        membersWithProfile.add(FamilyMemberWithProfile(
          member: member,
          email: email,
          documentCount: documentCount,
          timelineEventCount: timelineEventCount,
          recentDiseases: recentDiseases,
        ));
      }

      return membersWithProfile;
    } catch (e) {
      throw Exception('Failed to get family members with profile: $e');
    }
  }

  /// Create default "Me" entry as first family member
  Future<FamilyMember> createDefaultSelfMember() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile
      final userProfile = await _client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      final user = UserProfile.fromJson(userProfile);

      // Check if already exists (check by relationship 'Me' since is_self column doesn't exist)
      final existing = await _client
          .from('family_members')
          .select()
          .eq('user_id', userId)
          .eq('relationship', 'Me')
          .maybeSingle();

      if (existing != null) {
        return FamilyMember.fromJson(existing);
      }

      // Create "Me" family member
      final selfMember = FamilyMember(
        userId: userId,
        linkedUserId: null, // Self entry doesn't link to another user
        fullName: user.fullName ?? user.email,
        relationship: 'Me',
        gender: user.gender,
        bloodGroup: user.bloodGroup,
        chronicDiseases: user.chronicDiseases,
        allergies: user.allergies,
        isSelf: true,
        createdAt: DateTime.now(),
      );

      return await addFamilyMember(selfMember);
    } catch (e) {
      throw Exception('Failed to create self member: $e');
    }
  }
}
