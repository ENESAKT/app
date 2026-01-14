import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/api_keys.dart';

/// Chatbot Screen - Gemini AI Sohbet
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser})
    : time = DateTime.now();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late GenerativeModel _model;
  late ChatSession _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _messages.add(
      _ChatMessage(
        text:
            'Merhaba! 👋 Ben Gemini AI asistanınızım. Size nasıl yardımcı olabilirim?',
        isUser: false,
      ),
    );
  }

  void _initGemini() {
    _model = GenerativeModel(model: 'gemini-pro', apiKey: ApiKeys.googleGemini);
    _chat = _model.startChat();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply = response.text ?? 'Yanıt alınamadı.';
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'Hata: ${e.toString().split(':').last.trim()}',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        _ChatMessage(
          text: 'Sohbet temizlendi. Yeni bir konuşma başlatabiliriz! 🚀',
          isUser: false,
        ),
      );
    });
    _chat = _model.startChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4285F4), Color(0xFF0F9D58), Color(0xFF4285F4)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildMessagesList()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gemini AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Google AI Studio',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _clearChat,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading)
          return _buildTypingIndicator();
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser ? Colors.black87 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: isUser ? const Color(0xFF4285F4) : Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildAvatar(false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Text('Yazıyor...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.send,
                    color: const Color(0xFF4285F4),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
