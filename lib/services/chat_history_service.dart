import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing chat conversations and messages
class ChatHistoryService {
  final _supabase = Supabase.instance.client;

  /// Create a new conversation
  Future<String?> createConversation({
    required String userId,
    required String title,
  }) async {
    try {
      final response = await _supabase.from('chat_conversations').insert({
        'user_id': userId,
        'title': title,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  /// Get all conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get messages for a specific conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Save a message to a conversation
  Future<void> saveMessage({
    required String conversationId,
    required String message,
    required String response,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'conversation_id': conversationId,
        'message': message,
        'response': response,
      });
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  /// Update conversation title (rename)
  Future<void> updateConversationTitle({
    required String conversationId,
    required String newTitle,
  }) async {
    try {
      await _supabase
          .from('chat_conversations')
          .update({'title': newTitle})
          .eq('id', conversationId);
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }

  /// Delete a conversation (and all its messages)
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  /// Delete all conversations for a user
  Future<void> deleteAllConversations(String userId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error deleting all conversations: $e');
    }
  }

  /// Generate title from first message
  String generateTitle(String firstMessage) {
    // Take first 50 characters or until first newline
    String title = firstMessage.split('\n').first;
    if (title.length > 50) {
      title = '${title.substring(0, 50)}...';
    }
    return title;
  }
}
