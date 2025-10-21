import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_history.dart';
import 'supabase_service.dart';

/// Service for managing medical history timeline
/// Provides CRUD operations for medical events
class TimelineService {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch all medical history events for a user
  /// Returns events sorted by event date (newest first)
  Future<List<MedicalHistory>> getMedicalHistory(String userId) async {
    try {
      final response = await _client
          .from('medical_history')
          .select()
          .eq('user_id', userId)
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch medical history: $e');
    }
  }

  /// Get medical history filtered by date range
  Future<List<MedicalHistory>> getMedicalHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('medical_history')
          .select()
          .eq('user_id', userId)
          .gte('event_date', startDate.toIso8601String())
          .lte('event_date', endDate.toIso8601String())
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch medical history by date range: $e');
    }
  }

  /// Get medical history filtered by event type
  Future<List<MedicalHistory>> getMedicalHistoryByType({
    required String userId,
    required String eventType,
  }) async {
    try {
      final response = await _client
          .from('medical_history')
          .select()
          .eq('user_id', userId)
          .eq('event_type', eventType)
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch medical history by type: $e');
    }
  }

  /// Get medical history filtered by disease
  Future<List<MedicalHistory>> getMedicalHistoryByDisease({
    required String userId,
    required String disease,
  }) async {
    try {
      final response = await _client
          .from('medical_history')
          .select()
          .eq('user_id', userId)
          .ilike('disease', '%$disease%')
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch medical history by disease: $e');
    }
  }

  /// Get a single medical history event by ID
  Future<MedicalHistory?> getMedicalHistoryById(String id) async {
    try {
      final response = await _client
          .from('medical_history')
          .select()
          .eq('id', id)
          .single();

      return MedicalHistory.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Add a new medical history event
  Future<MedicalHistory> addMedicalHistory(MedicalHistory history) async {
    try {
      final response = await _client
          .from('medical_history')
          .insert(history.toJson())
          .select()
          .single();

      return MedicalHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add medical history: $e');
    }
  }

  /// Update an existing medical history event
  Future<MedicalHistory> updateMedicalHistory(MedicalHistory history) async {
    try {
      final response = await _client
          .from('medical_history')
          .update(history.toJson())
          .eq('id', history.id!)
          .select()
          .single();

      return MedicalHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update medical history: $e');
    }
  }

  /// Delete a medical history event
  Future<void> deleteMedicalHistory(String id) async {
    try {
      await _client.from('medical_history').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete medical history: $e');
    }
  }

  /// Get unique event types for filtering
  Future<List<String>> getEventTypes(String userId) async {
    try {
      final response = await _client
          .from('medical_history')
          .select('event_type')
          .eq('user_id', userId);

      final types = (response as List)
          .map((e) => e['event_type'] as String)
          .toSet()
          .toList();

      return types..sort();
    } catch (e) {
      throw Exception('Failed to fetch event types: $e');
    }
  }

  /// Get unique diseases for filtering
  Future<List<String>> getDiseases(String userId) async {
    try {
      final response = await _client
          .from('medical_history')
          .select('disease')
          .eq('user_id', userId)
          .not('disease', 'is', null);

      final diseases = (response as List)
          .where((e) => e['disease'] != null)
          .map((e) => e['disease'] as String)
          .toSet()
          .toList();

      return diseases..sort();
    } catch (e) {
      throw Exception('Failed to fetch diseases: $e');
    }
  }

  /// Search medical history by keyword
  Future<List<MedicalHistory>> searchMedicalHistory({
    required String userId,
    required String keyword,
  }) async {
    try {
      final response = await _client
          .from('medical_history')
          .select()
          .eq('user_id', userId)
          .or('disease.ilike.%$keyword%,symptoms.ilike.%$keyword%,treatment.ilike.%$keyword%,notes.ilike.%$keyword%')
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search medical history: $e');
    }
  }
}
