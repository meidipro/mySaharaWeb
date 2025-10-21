import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_history.dart';

/// Service for managing medical timeline (CRUD operations)
class MedicalTimelineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all medical timeline events for current user
  Future<List<MedicalHistory>> getTimelineEvents() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', _currentUserId!)
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch timeline events: $e');
    }
  }

  /// Get a single timeline event by ID
  Future<MedicalHistory?> getTimelineEventById(String id) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('id', id)
          .eq('user_id', _currentUserId!)
          .single();

      return MedicalHistory.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Add new timeline event
  Future<MedicalHistory> addTimelineEvent(MedicalHistory event) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final eventData = event.toJson();
      eventData['user_id'] = _currentUserId;

      final response = await _supabase
          .from('medical_history')
          .insert(eventData)
          .select()
          .single();

      return MedicalHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add timeline event: $e');
    }
  }

  /// Update existing timeline event
  Future<MedicalHistory> updateTimelineEvent(
    String id,
    MedicalHistory event,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final eventData = event.toJson();
      // Remove fields that should not be updated
      eventData.remove('id');
      eventData.remove('user_id');
      eventData.remove('created_at');
      eventData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('medical_history')
          .update(eventData)
          .eq('id', id)
          .eq('user_id', _currentUserId!)
          .select()
          .single();

      return MedicalHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update timeline event: $e');
    }
  }

  /// Delete timeline event
  Future<void> deleteTimelineEvent(String id) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('medical_history')
          .delete()
          .eq('id', id)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      throw Exception('Failed to delete timeline event: $e');
    }
  }

  /// Get timeline events by event type
  Future<List<MedicalHistory>> getEventsByType(String eventType) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('event_type', eventType)
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events by type: $e');
    }
  }

  /// Get timeline events by date range
  Future<List<MedicalHistory>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', _currentUserId!)
          .gte('event_date', startDate.toIso8601String())
          .lte('event_date', endDate.toIso8601String())
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events by date range: $e');
    }
  }

  /// Search timeline events by keyword
  Future<List<MedicalHistory>> searchTimelineEvents(String keyword) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', _currentUserId!)
          .or('disease.ilike.%$keyword%,symptoms.ilike.%$keyword%,doctor_name.ilike.%$keyword%,hospital.ilike.%$keyword%')
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search timeline events: $e');
    }
  }

  /// Get recent timeline events
  Future<List<MedicalHistory>> getRecentEvents({int limit = 10}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent events: $e');
    }
  }

  /// Get timeline statistics
  Future<Map<String, int>> getTimelineStats() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final events = await getTimelineEvents();

      // Count by event type
      final stats = <String, int>{};
      for (final event in events) {
        stats[event.eventType] = (stats[event.eventType] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch timeline stats: $e');
    }
  }
}
