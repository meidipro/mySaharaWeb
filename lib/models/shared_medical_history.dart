class SharedMedicalHistory {
  final String? id;
  final String userId;
  final String shareCode;
  final List<String> medicalHistoryIds;
  final DateTime expiresAt;
  final DateTime createdAt;

  SharedMedicalHistory({
    this.id,
    required this.userId,
    required this.shareCode,
    required this.medicalHistoryIds,
    required this.expiresAt,
    required this.createdAt,
  });

  factory SharedMedicalHistory.fromJson(Map<String, dynamic> json) {
    return SharedMedicalHistory(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      shareCode: json['share_code'] as String,
      medicalHistoryIds: (json['medical_history_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'share_code': shareCode,
      'medical_history_ids': medicalHistoryIds,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }
}
