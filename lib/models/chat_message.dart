class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? modelUsed;
  final double? confidence;
  final List<String> suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.modelUsed,
    this.confidence,
    this.suggestions = const [],
  });

  /// Create a copy of this message with updated fields
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? modelUsed,
    double? confidence,
    List<String>? suggestions,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      modelUsed: modelUsed ?? this.modelUsed,
      confidence: confidence ?? this.confidence,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  /// Convert to JSON for API calls
  Map<String, String> toJson() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': text,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['content'] ?? '',
      isUser: json['role'] == 'user',
      timestamp: DateTime.now(),
      modelUsed: json['model_used'],
      confidence: json['confidence']?.toDouble(),
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}
