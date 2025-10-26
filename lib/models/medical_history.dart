class MedicalHistory {
  final String? id;
  final String userId;
  final String? familyMemberId; // Links to specific family member
  final DateTime eventDate;
  final String eventType; // diagnosis, treatment, surgery, etc.
  final String? disease;
  final String? symptoms;
  final String? doctorName;
  final String? doctorSpecialty;
  final String? hospital;
  final String? treatment;
  final String? medications;
  final String? notes;
  final List<String>? documentIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalHistory({
    this.id,
    required this.userId,
    this.familyMemberId,
    required this.eventDate,
    required this.eventType,
    this.disease,
    this.symptoms,
    this.doctorName,
    this.doctorSpecialty,
    this.hospital,
    this.treatment,
    this.medications,
    this.notes,
    this.documentIds,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      familyMemberId: json['family_member_id'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      eventType: json['event_type'] as String,
      disease: json['disease'] as String?,
      symptoms: json['symptoms'] as String?,
      doctorName: json['doctor_name'] as String?,
      doctorSpecialty: json['doctor_specialty'] as String?,
      hospital: json['hospital'] as String?,
      treatment: json['treatment'] as String?,
      medications: json['medications'] as String?,
      notes: json['notes'] as String?,
      documentIds: (json['document_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      'event_date': eventDate.toIso8601String(),
      'event_type': eventType,
      'disease': disease,
      'symptoms': symptoms,
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
      'hospital': hospital,
      'treatment': treatment,
      'medications': medications,
      'notes': notes,
      'document_ids': documentIds,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
