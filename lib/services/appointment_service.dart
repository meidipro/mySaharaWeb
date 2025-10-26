import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing appointments
class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all appointments for a user
  Future<List<Map<String, dynamic>>> getAppointments(String userId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  /// Get upcoming appointments (next 30 days by default)
  Future<List<Map<String, dynamic>>> getUpcomingAppointments(
    String userId, {
    int daysAhead = 30,
  }) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .gte('appointment_date', now.toIso8601String())
          .lte('appointment_date', futureDate.toIso8601String())
          .inFilter('status', ['scheduled', 'rescheduled'])
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
      return [];
    }
  }

  /// Get past appointments
  Future<List<Map<String, dynamic>>> getPastAppointments(String userId) async {
    try {
      final now = DateTime.now();

      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .lt('appointment_date', now.toIso8601String())
          .order('appointment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching past appointments: $e');
      return [];
    }
  }

  /// Get appointments by status
  Future<List<Map<String, dynamic>>> getAppointmentsByStatus(
    String userId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .eq('status', status)
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching appointments by status: $e');
      return [];
    }
  }

  /// Get appointments for a specific date range
  Future<List<Map<String, dynamic>>> getAppointmentsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String())
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching appointments by date range: $e');
      return [];
    }
  }

  /// Add new appointment
  Future<String?> addAppointment({
    required String userId,
    String? familyMemberId, // Optional: for family member's appointments
    required String doctorName,
    String? specialty,
    required DateTime appointmentDate,
    String? location,
    String? geoCoordinates, // "lat,lng" format
    String? reasonForVisit,
    String visitType = 'in-person',
    String status = 'scheduled',
    bool reminder24h = true,
    bool reminder1h = true,
    String? notes,
    int durationMinutes = 30,
  }) async {
    try {
      final response = await _supabase.from('appointments').insert({
        'user_id': userId,
        if (familyMemberId != null) 'family_member_id': familyMemberId,
        'doctor_name': doctorName,
        'specialty': specialty,
        'appointment_date': appointmentDate.toIso8601String(),
        'location': location,
        'reason_for_visit': reasonForVisit,
        'visit_type': visitType,
        'status': status,
        'reminder_24h': reminder24h,
        'reminder_1h': reminder1h,
        'notes': notes,
        'duration_minutes': durationMinutes,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error adding appointment: $e');
      return null;
    }
  }

  /// Update appointment
  Future<bool> updateAppointment({
    required String appointmentId,
    String? doctorName,
    String? specialty,
    DateTime? appointmentDate,
    String? location,
    String? geoCoordinates,
    String? reasonForVisit,
    String? visitType,
    String? status,
    bool? reminder24h,
    bool? reminder1h,
    String? notes,
    int? durationMinutes,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (doctorName != null) updateData['doctor_name'] = doctorName;
      if (specialty != null) updateData['specialty'] = specialty;
      if (appointmentDate != null) {
        updateData['appointment_date'] = appointmentDate.toIso8601String();
      }
      if (location != null) updateData['location'] = location;
      if (reasonForVisit != null) updateData['reason_for_visit'] = reasonForVisit;
      if (visitType != null) updateData['visit_type'] = visitType;
      if (status != null) updateData['status'] = status;
      if (reminder24h != null) updateData['reminder_24h'] = reminder24h;
      if (reminder1h != null) updateData['reminder_1h'] = reminder1h;
      if (notes != null) updateData['notes'] = notes;
      if (durationMinutes != null) updateData['duration_minutes'] = durationMinutes;

      if (updateData.isEmpty) return false;

      await _supabase
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      return true;
    } catch (e) {
      print('Error updating appointment: $e');
      return false;
    }
  }

  /// Delete appointment
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _supabase.from('appointments').delete().eq('id', appointmentId);
      return true;
    } catch (e) {
      print('Error deleting appointment: $e');
      return false;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    try {
      await _supabase.from('appointments').update({
        'status': 'cancelled',
        if (reason != null) 'notes': reason,
      }).eq('id', appointmentId);

      return true;
    } catch (e) {
      print('Error cancelling appointment: $e');
      return false;
    }
  }

  /// Mark appointment as completed
  Future<bool> markAsCompleted(String appointmentId, {String? notes}) async {
    try {
      await _supabase.from('appointments').update({
        'status': 'completed',
        if (notes != null) 'notes': notes,
      }).eq('id', appointmentId);

      return true;
    } catch (e) {
      print('Error marking appointment as completed: $e');
      return false;
    }
  }

  /// Mark appointment as missed
  Future<bool> markAsMissed(String appointmentId) async {
    try {
      await _supabase.from('appointments').update({
        'status': 'missed',
      }).eq('id', appointmentId);

      return true;
    } catch (e) {
      print('Error marking appointment as missed: $e');
      return false;
    }
  }

  /// Get appointment statistics
  Future<Map<String, dynamic>> getAppointmentStats(String userId) async {
    try {
      final appointments = await getAppointments(userId);

      final now = DateTime.now();
      final scheduled = appointments.where((a) => a['status'] == 'scheduled').length;
      final completed = appointments.where((a) => a['status'] == 'completed').length;
      final cancelled = appointments.where((a) => a['status'] == 'cancelled').length;
      final missed = appointments.where((a) => a['status'] == 'missed').length;

      final upcoming = appointments.where((a) {
        final date = DateTime.parse(a['appointment_date']);
        return date.isAfter(now) && (a['status'] == 'scheduled' || a['status'] == 'rescheduled');
      }).length;

      return {
        'total': appointments.length,
        'scheduled': scheduled,
        'completed': completed,
        'cancelled': cancelled,
        'missed': missed,
        'upcoming': upcoming,
      };
    } catch (e) {
      print('Error getting appointment stats: $e');
      return {
        'total': 0,
        'scheduled': 0,
        'completed': 0,
        'cancelled': 0,
        'missed': 0,
        'upcoming': 0,
      };
    }
  }

  /// Get appointment history (audit log)
  Future<List<Map<String, dynamic>>> getAppointmentHistory(
    String appointmentId,
  ) async {
    try {
      final response = await _supabase
          .from('appointment_history')
          .select()
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching appointment history: $e');
      return [];
    }
  }

  /// Add custom reminder
  Future<String?> addCustomReminder({
    required String appointmentId,
    required DateTime reminderTime,
    String reminderType = 'custom',
    String notificationMethod = 'push',
  }) async {
    try {
      final response = await _supabase.from('appointment_reminders').insert({
        'appointment_id': appointmentId,
        'reminder_time': reminderTime.toIso8601String(),
        'reminder_type': reminderType,
        'notification_method': notificationMethod,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error adding custom reminder: $e');
      return null;
    }
  }

  /// Get reminders for an appointment
  Future<List<Map<String, dynamic>>> getReminders(String appointmentId) async {
    try {
      final response = await _supabase
          .from('appointment_reminders')
          .select()
          .eq('appointment_id', appointmentId)
          .order('reminder_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  /// Mark reminder as sent
  Future<bool> markReminderAsSent(String reminderId) async {
    try {
      await _supabase.from('appointment_reminders').update({
        'sent': true,
        'sent_at': DateTime.now().toIso8601String(),
      }).eq('id', reminderId);

      return true;
    } catch (e) {
      print('Error marking reminder as sent: $e');
      return false;
    }
  }

  /// Search appointments by doctor name or specialty
  Future<List<Map<String, dynamic>>> searchAppointments(
    String userId,
    String query,
  ) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .or('doctor_name.ilike.%$query%,specialty.ilike.%$query%')
          .order('appointment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching appointments: $e');
      return [];
    }
  }

  // =============================================
  // PREPARATION CHECKLIST METHODS
  // =============================================

  /// Get preparation checklist for appointment
  Future<Map<String, dynamic>?> getPreparation(String appointmentId) async {
    try {
      final response = await _supabase
          .from('appointment_preparation')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching preparation: $e');
      return null;
    }
  }

  /// Create or update preparation checklist
  Future<String?> savePreparation({
    required String appointmentId,
    List<String>? questions,
    List<String>? symptoms,
    String? updatesSinceLastVisit,
    List<String>? currentMedications,
    List<String>? documentsToBring,
    List<String>? aiSuggestions,
  }) async {
    try {
      // Check if preparation already exists
      final existing = await getPreparation(appointmentId);

      final data = {
        'appointment_id': appointmentId,
        if (questions != null) 'questions': questions,
        if (symptoms != null) 'symptoms': symptoms,
        if (updatesSinceLastVisit != null)
          'updates_since_last_visit': updatesSinceLastVisit,
        if (currentMedications != null) 'current_medications': currentMedications,
        if (documentsToBring != null) 'documents_to_bring': documentsToBring,
        if (aiSuggestions != null) 'ai_suggestions': aiSuggestions,
      };

      if (existing != null) {
        // Update existing
        await _supabase
            .from('appointment_preparation')
            .update(data)
            .eq('id', existing['id']);
        return existing['id'] as String;
      } else {
        // Create new
        final response = await _supabase
            .from('appointment_preparation')
            .insert(data)
            .select('id')
            .single();
        return response['id'] as String;
      }
    } catch (e) {
      print('Error saving preparation: $e');
      return null;
    }
  }

  /// Add question to preparation checklist
  Future<bool> addQuestion(String appointmentId, String question) async {
    try {
      final prep = await getPreparation(appointmentId);
      final questions = prep != null
          ? List<String>.from(prep['questions'] ?? [])
          : <String>[];

      questions.add(question);

      await savePreparation(
        appointmentId: appointmentId,
        questions: questions,
      );

      return true;
    } catch (e) {
      print('Error adding question: $e');
      return false;
    }
  }

  /// Remove question from preparation checklist
  Future<bool> removeQuestion(String appointmentId, int index) async {
    try {
      final prep = await getPreparation(appointmentId);
      if (prep == null) return false;

      final questions = List<String>.from(prep['questions'] ?? []);
      if (index < 0 || index >= questions.length) return false;

      questions.removeAt(index);

      await savePreparation(
        appointmentId: appointmentId,
        questions: questions,
      );

      return true;
    } catch (e) {
      print('Error removing question: $e');
      return false;
    }
  }

  /// Add symptom to preparation checklist
  Future<bool> addSymptom(String appointmentId, String symptom) async {
    try {
      final prep = await getPreparation(appointmentId);
      final symptoms = prep != null
          ? List<String>.from(prep['symptoms'] ?? [])
          : <String>[];

      symptoms.add(symptom);

      await savePreparation(
        appointmentId: appointmentId,
        symptoms: symptoms,
      );

      return true;
    } catch (e) {
      print('Error adding symptom: $e');
      return false;
    }
  }

  /// Remove symptom from preparation checklist
  Future<bool> removeSymptom(String appointmentId, int index) async {
    try {
      final prep = await getPreparation(appointmentId);
      if (prep == null) return false;

      final symptoms = List<String>.from(prep['symptoms'] ?? []);
      if (index < 0 || index >= symptoms.length) return false;

      symptoms.removeAt(index);

      await savePreparation(
        appointmentId: appointmentId,
        symptoms: symptoms,
      );

      return true;
    } catch (e) {
      print('Error removing symptom: $e');
      return false;
    }
  }

  /// Add current medication to preparation checklist
  Future<bool> addCurrentMedication(
      String appointmentId, String medication) async {
    try {
      final prep = await getPreparation(appointmentId);
      final medications = prep != null
          ? List<String>.from(prep['current_medications'] ?? [])
          : <String>[];

      medications.add(medication);

      await savePreparation(
        appointmentId: appointmentId,
        currentMedications: medications,
      );

      return true;
    } catch (e) {
      print('Error adding medication: $e');
      return false;
    }
  }

  /// Remove current medication from preparation checklist
  Future<bool> removeCurrentMedication(String appointmentId, int index) async {
    try {
      final prep = await getPreparation(appointmentId);
      if (prep == null) return false;

      final medications =
          List<String>.from(prep['current_medications'] ?? []);
      if (index < 0 || index >= medications.length) return false;

      medications.removeAt(index);

      await savePreparation(
        appointmentId: appointmentId,
        currentMedications: medications,
      );

      return true;
    } catch (e) {
      print('Error removing medication: $e');
      return false;
    }
  }

  /// Add document to bring to preparation checklist
  Future<bool> addDocumentToBring(String appointmentId, String document) async {
    try {
      final prep = await getPreparation(appointmentId);
      final documents = prep != null
          ? List<String>.from(prep['documents_to_bring'] ?? [])
          : <String>[];

      documents.add(document);

      await savePreparation(
        appointmentId: appointmentId,
        documentsToBring: documents,
      );

      return true;
    } catch (e) {
      print('Error adding document: $e');
      return false;
    }
  }

  /// Remove document from preparation checklist
  Future<bool> removeDocumentToBring(String appointmentId, int index) async {
    try {
      final prep = await getPreparation(appointmentId);
      if (prep == null) return false;

      final documents = List<String>.from(prep['documents_to_bring'] ?? []);
      if (index < 0 || index >= documents.length) return false;

      documents.removeAt(index);

      await savePreparation(
        appointmentId: appointmentId,
        documentsToBring: documents,
      );

      return true;
    } catch (e) {
      print('Error removing document: $e');
      return false;
    }
  }

  /// Update AI suggestions for preparation
  Future<bool> updateAISuggestions(
    String appointmentId,
    List<String> suggestions,
  ) async {
    try {
      await savePreparation(
        appointmentId: appointmentId,
        aiSuggestions: suggestions,
      );

      return true;
    } catch (e) {
      print('Error updating AI suggestions: $e');
      return false;
    }
  }

  // =============================================
  // FOLLOW-UP METHODS
  // =============================================

  /// Get follow-up notes for appointment
  Future<Map<String, dynamic>?> getFollowUp(String appointmentId) async {
    try {
      final response = await _supabase
          .from('appointment_followup')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching follow-up: $e');
      return null;
    }
  }

  /// Save follow-up notes
  Future<String?> saveFollowUp({
    required String appointmentId,
    String? diagnosis,
    List<String>? prescribedMedications,
    String? instructions,
    bool? nextVisitRecommended,
    DateTime? nextVisitDate,
    String? doctorNotes,
    String? patientNotes,
  }) async {
    try {
      // Check if follow-up already exists
      final existing = await getFollowUp(appointmentId);

      final data = {
        'appointment_id': appointmentId,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (prescribedMedications != null)
          'prescribed_medications': prescribedMedications,
        if (instructions != null) 'instructions': instructions,
        if (nextVisitRecommended != null)
          'next_visit_recommended': nextVisitRecommended,
        if (nextVisitDate != null)
          'next_visit_date': nextVisitDate.toIso8601String(),
        if (doctorNotes != null) 'doctor_notes': doctorNotes,
        if (patientNotes != null) 'patient_notes': patientNotes,
      };

      if (existing != null) {
        // Update existing
        await _supabase
            .from('appointment_followup')
            .update(data)
            .eq('id', existing['id']);
        return existing['id'] as String;
      } else {
        // Create new
        final response = await _supabase
            .from('appointment_followup')
            .insert(data)
            .select('id')
            .single();
        return response['id'] as String;
      }
    } catch (e) {
      print('Error saving follow-up: $e');
      return null;
    }
  }
}
