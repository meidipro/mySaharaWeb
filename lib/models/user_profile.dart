class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? allergies;
  final String? chronicDiseases;
  final String? emergencyContact;
  final String? emergencyContactName;
  final String? profileImageUrl;
  final String familyCode; // Unique permanent family code
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.allergies,
    this.chronicDiseases,
    this.emergencyContact,
    this.emergencyContactName,
    this.profileImageUrl,
    required this.familyCode,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      allergies: json['allergies'] as String?,
      chronicDiseases: json['chronic_diseases'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      familyCode: json['family_code'] as String? ?? '', // Default to empty if null
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'chronic_diseases': chronicDiseases,
      'emergency_contact': emergencyContact,
      'emergency_contact_name': emergencyContactName,
      'profile_image_url': profileImageUrl,
      'family_code': familyCode,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? chronicDiseases,
    String? emergencyContact,
    String? emergencyContactName,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      familyCode: familyCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
