import 'chat_message.dart';

class ChatHistory {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final String language;
  final int messageCount;

  ChatHistory({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.language,
    required this.messageCount,
  });

  /// Create a copy with updated fields
  ChatHistory copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? language,
    int? messageCount,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      language: language ?? this.language,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'language': language,
      'messageCount': messageCount,
    };
  }

  /// Create from JSON
  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => ChatMessage.fromJson(m))
          .toList() ?? [],
      language: json['language'] ?? 'en',
      messageCount: json['messageCount'] ?? 0,
    );
  }

  /// Generate a title from the first user message
  static String generateTitle(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'New Chat';
    
    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );
    
    String title = firstUserMessage.text;
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }
    
    return title.isEmpty ? 'New Chat' : title;
  }

  /// Get preview text (last few messages)
  String getPreview() {
    if (messages.isEmpty) return 'No messages yet';
    
    final lastMessages = messages.length > 2 
        ? messages.sublist(messages.length - 2)
        : messages;
    return lastMessages.map((m) => m.isUser ? 'You: ${m.text}' : 'AI: ${m.text}').join('\n');
  }

  /// Get duration since last update
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
