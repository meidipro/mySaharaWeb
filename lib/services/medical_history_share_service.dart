import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_medical_history.dart';
import '../models/medical_history.dart';
import '../models/medical_document.dart';

/// Service for managing medical history sharing via QR codes
class MedicalHistoryShareService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Generate a random 8-character share code
  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Create a share session for selected medical histories
  Future<SharedMedicalHistory> createShare(
    List<String> medicalHistoryIds,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (medicalHistoryIds.isEmpty) {
        throw Exception('No medical histories selected');
      }

      // Generate unique share code
      final shareCode = _generateShareCode();

      // Set expiry to 10 minutes from now (in UTC)
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(minutes: 10));

      final shareData = {
        'user_id': _currentUserId,
        'share_code': shareCode,
        'medical_history_ids': medicalHistoryIds,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('shared_medical_history')
          .insert(shareData)
          .select()
          .single();

      return SharedMedicalHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create share: $e');
    }
  }

  /// Get share by share code (for doctors scanning QR)
  Future<SharedMedicalHistory?> getShareByCode(String shareCode) async {
    try {
      final response = await _supabase
          .from('shared_medical_history')
          .select()
          .eq('share_code', shareCode)
          .single();

      final share = SharedMedicalHistory.fromJson(response);

      // Check if expired
      if (share.isExpired) {
        return null;
      }

      return share;
    } catch (e) {
      return null;
    }
  }

  /// Get medical histories for a share
  Future<List<MedicalHistory>> getSharedMedicalHistories(
    String shareCode,
  ) async {
    try {
      // First get the share
      final share = await getShareByCode(shareCode);
      if (share == null) {
        throw Exception('Share not found or expired');
      }

      // Get the medical histories
      final response = await _supabase
          .from('medical_history')
          .select()
          .inFilter('id', share.medicalHistoryIds)
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shared medical histories: $e');
    }
  }

  /// Get documents for shared medical histories
  Future<List<MedicalDocument>> getSharedDocuments(
    String shareCode,
  ) async {
    try {
      // First get the medical histories
      final histories = await getSharedMedicalHistories(shareCode);

      // Collect all document IDs
      final documentIds = <String>{};
      for (final history in histories) {
        if (history.documentIds != null) {
          documentIds.addAll(history.documentIds!);
        }
      }

      if (documentIds.isEmpty) {
        return [];
      }

      // Fetch all documents
      final response = await _supabase
          .from('medical_documents')
          .select()
          .inFilter('id', documentIds.toList());

      return (response as List)
          .map((json) => MedicalDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shared documents: $e');
    }
  }

  /// Delete expired shares (cleanup)
  Future<void> deleteExpiredShares() async {
    try {
      await _supabase
          .from('shared_medical_history')
          .delete()
          .lt('expires_at', DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      // Silently fail - this is a cleanup operation
    }
  }

  /// Delete a specific share
  Future<void> deleteShare(String shareId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('shared_medical_history')
          .delete()
          .eq('id', shareId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete share: $e');
    }
  }

  /// Get user's active shares
  Future<List<SharedMedicalHistory>> getUserActiveShares() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('shared_medical_history')
          .select()
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SharedMedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active shares: $e');
    }
  }
}
