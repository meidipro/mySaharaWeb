import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing medications, reminders, and logs
class MedicationService {
  final _supabase = Supabase.instance.client;

  // =====================================================
  // MEDICATIONS
  // =====================================================

  /// Get all medications for a user
  Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    try {
      final response = await _supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medications: $e');
      return [];
    }
  }

  /// Add new medication
  Future<String?> addMedication({
    required String userId,
    required String name,
    String? genericName,
    String? brandName,
    required double dosageAmount,
    required String dosageUnit,
    required String form,
    String? prescribingDoctor,
    String? pharmacyInfo,
    String? prescriptionNumber,
    double? totalQuantity,
    double? remainingQuantity,
    required DateTime startDate,
    DateTime? endDate,
    bool isOngoing = true,
    String? instructions,
    String? sideEffects,
    String? notes,
  }) async {
    try {
      final response = await _supabase.from('medications').insert({
        'user_id': userId,
        'name': name,
        'generic_name': genericName,
        'brand_name': brandName,
        'dosage_amount': dosageAmount,
        'dosage_unit': dosageUnit,
        'form': form,
        'prescribing_doctor': prescribingDoctor,
        'pharmacy_info': pharmacyInfo,
        'prescription_number': prescriptionNumber,
        'total_quantity': totalQuantity,
        'remaining_quantity': remainingQuantity ?? totalQuantity,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_ongoing': isOngoing,
        'instructions': instructions,
        'side_effects': sideEffects,
        'notes': notes,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error adding medication: $e');
      return null;
    }
  }

  /// Update medication
  Future<bool> updateMedication({
    required String medicationId,
    String? name,
    String? genericName,
    double? dosageAmount,
    String? dosageUnit,
    double? remainingQuantity,
    String? instructions,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (genericName != null) data['generic_name'] = genericName;
      if (dosageAmount != null) data['dosage_amount'] = dosageAmount;
      if (dosageUnit != null) data['dosage_unit'] = dosageUnit;
      if (remainingQuantity != null) data['remaining_quantity'] = remainingQuantity;
      if (instructions != null) data['instructions'] = instructions;
      if (notes != null) data['notes'] = notes;

      await _supabase
          .from('medications')
          .update(data)
          .eq('id', medicationId);

      return true;
    } catch (e) {
      print('Error updating medication: $e');
      return false;
    }
  }

  /// Delete medication (soft delete)
  Future<bool> deleteMedication(String medicationId) async {
    try {
      await _supabase
          .from('medications')
          .update({'is_active': false})
          .eq('id', medicationId);
      return true;
    } catch (e) {
      print('Error deleting medication: $e');
      return false;
    }
  }

  // =====================================================
  // MEDICATION REMINDERS
  // =====================================================

  /// Get reminders for a medication
  Future<List<Map<String, dynamic>>> getReminders(String medicationId) async {
    try {
      final response = await _supabase
          .from('medication_reminders')
          .select()
          .eq('medication_id', medicationId)
          .eq('is_enabled', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  /// Add medication reminder
  Future<String?> addReminder({
    required String medicationId,
    required String userId,
    required String frequencyType,
    required Map<String, dynamic> frequencyValue,
    required List<String> reminderTimes,
    String? mealTiming,
    int snoozeDuration = 10,
  }) async {
    try {
      final response = await _supabase.from('medication_reminders').insert({
        'medication_id': medicationId,
        'user_id': userId,
        'frequency_type': frequencyType,
        'frequency_value': frequencyValue,
        'reminder_times': reminderTimes,
        'meal_timing': mealTiming,
        'snooze_duration': snoozeDuration,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error adding reminder: $e');
      return null;
    }
  }

  // =====================================================
  // MEDICATION LOGS
  // =====================================================

  /// Log medication intake
  Future<bool> logMedicationIntake({
    required String medicationId,
    required String userId,
    String? reminderId,
    required DateTime scheduledTime,
    DateTime? actualTime,
    required String status, // taken, missed, skipped
    double? dosageTaken,
    String? notes,
  }) async {
    try {
      await _supabase.from('medication_logs').insert({
        'medication_id': medicationId,
        'reminder_id': reminderId,
        'user_id': userId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'actual_time': actualTime?.toIso8601String(),
        'status': status,
        'dosage_taken': dosageTaken,
        'notes': notes,
      });

      return true;
    } catch (e) {
      print('Error logging medication: $e');
      return false;
    }
  }

  /// Get medication logs
  Future<List<Map<String, dynamic>>> getMedicationLogs({
    String? medicationId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('medication_logs').select();

      if (medicationId != null) {
        query = query.eq('medication_id', medicationId);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (startDate != null) {
        query = query.gte('scheduled_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('scheduled_time', endDate.toIso8601String());
      }

      final response = await query.order('scheduled_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  /// Get adherence statistics
  Future<Map<String, dynamic>> getAdherenceStats({
    required String userId,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final logs = await getMedicationLogs(
        userId: userId,
        startDate: startDate,
      );

      final total = logs.length;
      final taken = logs.where((log) => log['status'] == 'taken').length;
      final missed = logs.where((log) => log['status'] == 'missed').length;
      final skipped = logs.where((log) => log['status'] == 'skipped').length;

      final adherenceRate = total > 0 ? (taken / total * 100).round() : 0;

      return {
        'total': total,
        'taken': taken,
        'missed': missed,
        'skipped': skipped,
        'adherence_rate': adherenceRate,
        'period_days': days,
      };
    } catch (e) {
      print('Error calculating adherence: $e');
      return {
        'total': 0,
        'taken': 0,
        'missed': 0,
        'skipped': 0,
        'adherence_rate': 0,
        'period_days': days,
      };
    }
  }

  // =====================================================
  // VACCINES
  // =====================================================

  /// Get all vaccines for a user
  Future<List<Map<String, dynamic>>> getVaccines(String userId) async {
    try {
      final response = await _supabase
          .from('vaccines')
          .select()
          .eq('user_id', userId)
          .order('next_due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vaccines: $e');
      return [];
    }
  }

  /// Add vaccine record
  Future<String?> addVaccine({
    required String userId,
    required String vaccineName,
    String? vaccineType,
    required int doseNumber,
    int? totalDoses,
    DateTime? administeredDate,
    DateTime? nextDueDate,
    String? location,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await _supabase.from('vaccines').insert({
        'user_id': userId,
        'vaccine_name': vaccineName,
        'vaccine_type': vaccineType,
        'dose_number': doseNumber,
        'total_doses': totalDoses,
        'administered_date': administeredDate?.toIso8601String(),
        'next_due_date': nextDueDate?.toIso8601String(),
        'location': location,
        'status': status,
        'notes': notes,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error adding vaccine: $e');
      return null;
    }
  }
}
