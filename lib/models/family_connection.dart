class FamilyConnection {
  final String? id;
  final String userId;
  final String connectedUserId;
  final String relationship;
  final String connectionCode;
  final bool isAccepted;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  FamilyConnection({
    this.id,
    required this.userId,
    required this.connectedUserId,
    required this.relationship,
    required this.connectionCode,
    this.isAccepted = false,
    required this.createdAt,
    this.acceptedAt,
  });

  factory FamilyConnection.fromJson(Map<String, dynamic> json) {
    return FamilyConnection(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      connectedUserId: json['connected_user_id'] as String,
      relationship: json['relationship'] as String,
      connectionCode: json['connection_code'] as String,
      isAccepted: json['is_accepted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'connected_user_id': connectedUserId,
      'relationship': relationship,
      'connection_code': connectionCode,
      'is_accepted': isAccepted,
      'created_at': createdAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
    };
  }
}
