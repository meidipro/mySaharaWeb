class FamilyMember {
  final String? id;
  final String userId;
  final String? linkedUserId; // If they have their own account
  final String fullName;
  final String relationship; // father, mother, sibling, child, etc.
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? chronicDiseases;
  final String? medications;
  final String? allergies;
  final String? notes;
  final String? profileImageUrl;
  final bool isSelf; // True if this is the user's own profile
  final DateTime createdAt;
  final DateTime? updatedAt;

  FamilyMember({
    this.id,
    required this.userId,
    this.linkedUserId,
    required this.fullName,
    required this.relationship,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.chronicDiseases,
    this.medications,
    this.allergies,
    this.notes,
    this.profileImageUrl,
    this.isSelf = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      linkedUserId: json['linked_user_id'] as String?,
      fullName: json['full_name'] as String,
      relationship: json['relationship'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      chronicDiseases: json['chronic_diseases'] as String?,
      medications: json['medications'] as String?,
      allergies: json['allergies'] as String?,
      notes: json['notes'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isSelf: json['is_self'] as bool? ?? false,
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
      if (linkedUserId != null) 'linked_user_id': linkedUserId,
      'full_name': fullName,
      'relationship': relationship,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (chronicDiseases != null) 'chronic_diseases': chronicDiseases,
      if (medications != null) 'medications': medications,
      if (allergies != null) 'allergies': allergies,
      if (notes != null) 'notes': notes,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      // 'is_self': isSelf, // Removed - column doesn't exist in database
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Family invite code model
class FamilyInvite {
  final String? id;
  final String userId; // The user who generated the code
  final String inviteCode;
  final String? relationship; // Suggested relationship for the invitee
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  FamilyInvite({
    this.id,
    required this.userId,
    required this.inviteCode,
    this.relationship,
    required this.expiresAt,
    this.isUsed = false,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  factory FamilyInvite.fromJson(Map<String, dynamic> json) {
    return FamilyInvite(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      inviteCode: json['invite_code'] as String,
      relationship: json['relationship'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsed: json['is_used'] as bool? ?? false,
      usedBy: json['used_by'] as String?,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'invite_code': inviteCode,
      'relationship': relationship,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'used_by': usedBy,
      if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Family member with linked user profile data
class FamilyMemberWithProfile {
  final FamilyMember member;
  final String? email;
  final int documentCount;
  final int timelineEventCount;
  final List<String>? recentDiseases;

  FamilyMemberWithProfile({
    required this.member,
    this.email,
    this.documentCount = 0,
    this.timelineEventCount = 0,
    this.recentDiseases,
  });
}
