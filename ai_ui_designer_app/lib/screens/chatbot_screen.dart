import 'package:flutter/material.dart';
import 'package:ai_ui_designer_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class ChatMessage {
  final String role; // "user" or "bot"
  final String text;
  final bool isLoading;

  ChatMessage({required this.role, required this.text, this.isLoading = false});
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<ChatMessage> messages = [];
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      messages.add(
        ChatMessage(
          role: "bot",
          text:
              "Hello! 👋 I'm your AI design assistant. I can help you with UI/UX design, Flutter code, and project ideas. What would you like to know?",
        ),
      );
    });
  }

  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty || isTyping) return;

    // Add user message
    setState(() {
      messages.add(ChatMessage(role: "user", text: text));
      messageController.clear();
      isTyping = true;

      // Add loading message
      messages.add(
        ChatMessage(role: "bot", text: "🤔 Thinking...", isLoading: true),
      );
    });

    // Auto scroll
    _scrollToBottom();

    try {
      // Get user email for context (optional)
      final prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString("userEmail");
      String? userName = prefs.getString("userName") ?? "User";

      // Prepare the request body - only message is needed for chatbot
      Map<String, dynamic> requestBody = {"message": text};

      // Make API call to your backend chatbot endpoint
      final response = await http
          .post(
            Uri.parse('https://internship-backend-api.vercel.app/api/design/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': text}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      // Remove loading message
      setState(() {
        messages.removeLast();
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Extract the response (adjust based on your API response structure)
        String botResponse = _extractResponseFromData(data);

        setState(() {
          messages.add(ChatMessage(role: "bot", text: botResponse));
        });
      } else {
        // Handle error response
        String errorMessage =
            'Sorry, I encountered an error. Please try again.';
        try {
          var errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          // If response body is not JSON
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        setState(() {
          messages.add(ChatMessage(role: "bot", text: "❌ $errorMessage"));
        });
      }
    } catch (e) {
      // Remove loading message
      setState(() {
        if (messages.isNotEmpty && messages.last.isLoading) {
          messages.removeLast();
        }
      });

      // Handle network errors
      String errorMessage =
          'Network error: Unable to connect to AI service. Please check your connection.';

      setState(() {
        messages.add(
          ChatMessage(
            role: "bot",
            text: "❌ $errorMessage\n\nError details: ${e.toString()}",
          ),
        );
      });

      debugPrint("Chatbot Error: $e");
    } finally {
      setState(() {
        isTyping = false;
      });
      _scrollToBottom();
    }
  }

  String _extractResponseFromData(Map<String, dynamic> data) {
    // Check for chatbot response first (from /api/design/chat endpoint)
    if (data.containsKey('reply')) {
      return data['reply'];
    } else if (data.containsKey('response')) {
      return data['response'];
    } else if (data.containsKey('message')) {
      return data['message'];
    } else if (data.containsKey('text')) {
      return data['text'];
    } else if (data.containsKey('data')) {
      if (data['data'] is Map) {
        return data['data']['reply'] ??
            data['data']['response'] ??
            data['data']['message'] ??
            data['data'].toString();
      }
      return data['data'].toString();
    } else {
      // If no expected field found, return the entire response as string
      return jsonEncode(data);
    }
  }

  String _getChatContext() {
    // Build context from previous messages (last 6 messages for context)
    List<Map<String, String>> recentMessages = [];
    int startIndex = messages.length > 6 ? messages.length - 6 : 0;

    for (int i = startIndex; i < messages.length; i++) {
      if (!messages[i].isLoading) {
        recentMessages.add({
          'role': messages[i].role,
          'content': messages[i].text,
        });
      }
    }

    return jsonEncode(recentMessages);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearChat() {
    setState(() {
      messages.clear();
      _addWelcomeMessage();
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('AI Assistant'),
          ],
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t?.askSomething ??
                              'Ask me anything about UI/UX design!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '💡 Try: "Create a login screen" or "How to make a responsive layout?"',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg.role == "user";

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF6366F1)
                                      : isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: msg.isLoading
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    isUser
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF6366F1,
                                                          ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            msg.text,
                                            style: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : SelectableText(
                                        msg.text,
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF6366F1),
                                  size: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Suggested Prompts (when chat is empty or has few messages)
          if (messages.length <= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSuggestionChip('Create a login page'),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('Design a dashboard'),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('How to use GridView?'),
                  const SizedBox(width: 8),
                  _buildSuggestionChip('Flutter animation tips'),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    enabled: !isTyping,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          t?.askUI ?? 'Ask me anything about UI design...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: isTyping ? null : sendMessage,
                    backgroundColor: const Color(0xFF6366F1),
                    elevation: 0,
                    child: isTyping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        messageController.text = text;
        sendMessage();
      },
      backgroundColor: Colors.grey.shade200,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
