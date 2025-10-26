import 'package:supabase_flutter/supabase_flutter.dart';

/// Simplified Medication Service for managing medications
class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all medications for a user
  Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    try {
      final response = await _supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medications: $e');
      return [];
    }
  }

  /// Add new medication (SIMPLIFIED)
  Future<String?> addMedication({
    required String userId,
    String? familyMemberId, // Optional: for family member's medications
    required String name,
    String? genericName,
    String? brandName,
    required String form,
    required double dosageAmount,
    required String dosageUnit,
    int frequencyPerDay = 1,
    List<String> timing = const [], // ['morning', 'afternoon', 'evening', 'night']
    List<String>? reminderTimes, // ['08:00', '14:00', '20:00']
    bool takeWithFood = false,
    bool takeOnEmptyStomach = false,
    bool takeBeforeMeal = false,
    bool takeAfterMeal = false,
    DateTime? startDate,
    DateTime? endDate,
    bool isOngoing = true,
    double? totalQuantity,
    double? remainingQuantity,
    String? prescribingDoctor,
    String? instructions,
    String? notes,
  }) async {
    try {
      final response = await _supabase.from('medications').insert({
        'user_id': userId,
        if (familyMemberId != null) 'family_member_id': familyMemberId,
        'name': name,
        if (genericName != null) 'generic_name': genericName,
        if (brandName != null) 'brand_name': brandName,
        'form': form,
        'dosage_amount': dosageAmount,
        'dosage_unit': dosageUnit,
        'frequency_per_day': frequencyPerDay,
        'timing': timing,
        'reminder_times': reminderTimes ?? [],
        'take_with_food': takeWithFood,
        'take_on_empty_stomach': takeOnEmptyStomach,
        'take_before_meal': takeBeforeMeal,
        'take_after_meal': takeAfterMeal,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'is_ongoing': isOngoing,
        'total_quantity': totalQuantity,
        'quantity_remaining': remainingQuantity ?? totalQuantity,
        if (prescribingDoctor != null) 'prescribing_doctor': prescribingDoctor,
        'instructions': instructions,
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
    String? form,
    double? dosageAmount,
    String? dosageUnit,
    int? frequencyPerDay,
    List<String>? timing,
    List<String>? reminderTimes,
    bool? takeWithFood,
    bool? takeOnEmptyStomach,
    bool? takeBeforeMeal,
    bool? takeAfterMeal,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOngoing,
    int? totalQuantity,
    String? instructions,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (form != null) updateData['form'] = form;
      if (dosageAmount != null) updateData['dosage_amount'] = dosageAmount;
      if (dosageUnit != null) updateData['dosage_unit'] = dosageUnit;
      if (frequencyPerDay != null) updateData['frequency_per_day'] = frequencyPerDay;
      if (timing != null) updateData['timing'] = timing;
      if (reminderTimes != null) updateData['reminder_times'] = reminderTimes;
      if (takeWithFood != null) updateData['take_with_food'] = takeWithFood;
      if (takeOnEmptyStomach != null) updateData['take_on_empty_stomach'] = takeOnEmptyStomach;
      if (takeBeforeMeal != null) updateData['take_before_meal'] = takeBeforeMeal;
      if (takeAfterMeal != null) updateData['take_after_meal'] = takeAfterMeal;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String().split('T')[0];
      if (isOngoing != null) updateData['is_ongoing'] = isOngoing;
      if (totalQuantity != null) updateData['total_quantity'] = totalQuantity;
      if (instructions != null) updateData['instructions'] = instructions;
      if (notes != null) updateData['notes'] = notes;

      if (updateData.isEmpty) return false;

      await _supabase
          .from('medications')
          .update(updateData)
          .eq('id', medicationId);

      return true;
    } catch (e) {
      print('Error updating medication: $e');
      return false;
    }
  }

  /// Delete medication
  Future<bool> deleteMedication(String medicationId) async {
    try {
      await _supabase.from('medications').delete().eq('id', medicationId);
      return true;
    } catch (e) {
      print('Error deleting medication: $e');
      return false;
    }
  }

  /// Get medication reminders
  Future<List<Map<String, dynamic>>> getReminders(String medicationId) async {
    try {
      final response = await _supabase
          .from('medication_reminders')
          .select()
          .eq('medication_id', medicationId)
          .order('reminder_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  /// Add reminder time for medication
  Future<String?> addReminder({
    required String medicationId,
    required String reminderTime, // '08:00'
    String? reminderLabel, // 'morning', 'afternoon', etc.
    String? specificInstruction,
  }) async {
    try {
      final response = await _supabase.from('medication_reminders').insert({
        'medication_id': medicationId,
        'reminder_time': reminderTime,
        'reminder_label': reminderLabel,
        'specific_instruction': specificInstruction,
        'is_active': true,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error adding reminder: $e');
      return null;
    }
  }

  /// Log medication intake
  Future<bool> logMedicationIntake({
    required String medicationId,
    required DateTime scheduledTime,
    DateTime? takenAt,
    String status = 'taken', // 'taken', 'missed', 'skipped'
    String? notes,
  }) async {
    try {
      await _supabase.from('medication_logs').insert({
        'medication_id': medicationId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'taken_at': takenAt?.toIso8601String(),
        'status': status,
        'notes': notes,
      });

      // Update quantity if taken
      if (status == 'taken') {
        await _supabase.rpc('decrement_medication_quantity', params: {
          'med_id': medicationId,
        });
      }

      return true;
    } catch (e) {
      print('Error logging medication: $e');
      return false;
    }
  }

  /// Get adherence statistics
  Future<Map<String, dynamic>> getAdherenceStats({
    required String userId,
    int days = 30,
  }) async {
    try {
      final response = await _supabase
          .rpc('get_medication_adherence', params: {
        'p_user_id': userId,
        'p_days': days,
      })
          .single();

      return {
        'total_doses': response['total_doses'] ?? 0,
        'taken_doses': response['taken_doses'] ?? 0,
        'missed_doses': response['missed_doses'] ?? 0,
        'skipped_doses': response['skipped_doses'] ?? 0,
        'adherence_rate': response['adherence_rate'] ?? 0.0,
      };
    } catch (e) {
      print('Error getting adherence stats: $e');
      return {
        'total_doses': 0,
        'taken_doses': 0,
        'missed_doses': 0,
        'skipped_doses': 0,
        'adherence_rate': 0.0,
      };
    }
  }

  /// Get medication logs
  Future<List<Map<String, dynamic>>> getMedicationLogs(
    String medicationId, {
    int days = 30,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('medication_logs')
          .select()
          .eq('medication_id', medicationId)
          .gte('scheduled_time', since.toIso8601String())
          .order('scheduled_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medication logs: $e');
      return [];
    }
  }

  /// Get vaccines (kept for compatibility)
  Future<List<Map<String, dynamic>>> getVaccines(String userId) async {
    try {
      final response = await _supabase
          .from('vaccines')
          .select()
          .eq('user_id', userId)
          .order('administered_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vaccines: $e');
      return [];
    }
  }

  /// Add vaccine (kept for compatibility)
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
