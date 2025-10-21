class Medication {
  final String? id;
  final String userId;
  final String medicationName;
  final String? dosage;
  final String? frequency; // e.g., "twice daily", "3 times daily"
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<String>? reminderTimes; // e.g., ["08:00", "20:00"]
  final String? prescriptionId;
  final String? doctorName;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medication({
    this.id,
    required this.userId,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.instructions,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.reminderTimes,
    this.prescriptionId,
    this.doctorName,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      instructions: json['instructions'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      reminderTimes: (json['reminder_times'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      prescriptionId: json['prescription_id'] as String?,
      doctorName: json['doctor_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'reminder_times': reminderTimes,
      'prescription_id': prescriptionId,
      'doctor_name': doctorName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
