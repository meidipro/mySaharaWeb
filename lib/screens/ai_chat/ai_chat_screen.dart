import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/ai_service.dart';
import '../../services/chat_history_service.dart';
import 'chat_history_screen.dart';
import '../home/home_screen.dart';

/// Enhanced AI Health Doctor Screen with Conversation Support
class AiChatScreen extends StatefulWidget {
  final String? conversationId;

  const AiChatScreen({super.key, this.conversationId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatHistoryService _chatHistoryService = ChatHistoryService();

  bool _isLoading = false;
  bool _showSuggestions = true;
  String? _currentConversationId;
  String _conversationTitle = 'New Chat';

  // Suggested questions
  final List<Map<String, String>> _suggestedQuestions = [
    {
      'en': 'What should I eat for a healthy breakfast?',
      'bn': 'স্বাস্থ্যকর নাস্তায় কী খাব?'
    },
    {
      'en': 'How can I improve my sleep quality?',
      'bn': 'কীভাবে ঘুমের মান উন্নত করব?'
    },
    {
      'en': 'What are symptoms of dengue fever?',
      'bn': 'ডেঙ্গু জ্বরের লক্ষণ কী?'
    },
    {
      'en': 'How much water should I drink daily?',
      'bn': 'প্রতিদিন কত পানি পান করা উচিত?'
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    if (_currentConversationId != null) {
      _loadConversation();
    } else {
      _showWelcomeMessage();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    AIService.clearHistory();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    if (_currentConversationId == null) return;

    setState(() => _isLoading = true);

    final messages = await _chatHistoryService.getMessages(_currentConversationId!);

    setState(() {
      _messages.clear();
      for (var msg in messages) {
        _messages.add(ChatMessage(
          text: msg['message'] as String,
          isUser: true,
          timestamp: DateTime.parse(msg['created_at'] as String),
        ));
        _messages.add(ChatMessage(
          text: msg['response'] as String,
          isUser: false,
          timestamp: DateTime.parse(msg['created_at'] as String),
        ));
      }
      _isLoading = false;
      _showSuggestions = false;
    });

    _scrollToBottom();
  }

  void _showWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Hello! I\'m your AI Health Doctor. 👨‍⚕️\n\n'
              'আমি আপনার AI স্বাস্থ্য ডাক্তার। 👨‍⚕️\n\n'
              'I can help you with health questions, nutrition advice, lifestyle tips, and much more!\n\n'
              'আমি আপনাকে স্বাস্থ্য প্রশ্ন, পুষ্টি পরামর্শ, জীবনযাত্রার টিপস এবং আরও অনেক কিছুতে সাহায্য করতে পারি!\n\n'
              'Ask me anything in English or বাংলা!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  Future<void> _sendMessage({String? customMessage}) async {
    final message = customMessage ?? _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _showSuggestions = false;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get user context from auth provider
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) return;

      // Create conversation if this is the first message
      if (_currentConversationId == null) {
        final title = _chatHistoryService.generateTitle(message);
        _currentConversationId = await _chatHistoryService.createConversation(
          userId: user.id,
          title: title,
        );
        setState(() => _conversationTitle = title);
      }

      Map<String, dynamic>? userContext = {
        'age': user.age,
        'gender': user.gender,
        'location': 'Bangladesh',
      };

      final response = await AIService.chat(
        message,
        userContext: userContext,
      );

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Save to database
      if (_currentConversationId != null) {
        await _chatHistoryService.saveMessage(
          conversationId: _currentConversationId!,
          message: message,
          response: response,
        );
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If opened from home screen as a tab, go back to home
            // Otherwise go to chat history
            if (widget.conversationId == null) {
              Get.offAll(() => const HomeScreen());
            } else {
              Get.off(() => const ChatHistoryScreen());
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Health Doctor', style: TextStyle(fontSize: 16)),
            Text(
              _conversationTitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.off(() => const AiChatScreen(conversationId: null));
            },
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.off(() => const ChatHistoryScreen());
            },
            tooltip: 'Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested Questions (shown at start)
          if (_showSuggestions && _messages.length <= 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLang == 'bn'
                        ? 'আমাকে জিজ্ঞাসা করুন:'
                        : 'Ask me about:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedQuestions.map((q) {
                      final question = q[currentLang] ?? q['en']!;
                      return InkWell(
                        onTap: () => _sendMessage(customMessage: question),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            question,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Doctor is thinking... 💭',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: currentLang == 'bn'
                          ? 'আপনার প্রশ্ন লিখুন...'
                          : 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  mini: true,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Health Doctor',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (!message.isUser) const SizedBox(height: 8),
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
