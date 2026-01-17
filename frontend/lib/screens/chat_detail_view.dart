import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOHBET DETAY EKRANI - Dark Theme Realtime Mesajlaşma
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Özellikler:
/// - Supabase Realtime Stream ile anlık mesaj akışı
/// - Bubble UI: Benim mesajlarım sağda (Mor-Turuncu Gradient)
/// - Karşı tarafın mesajları solda (Koyu Gri #2C2C2C)
/// - Dark theme arka plan (#121212)
/// - Modern input area (emoji, attachment, gradient send button)
/// - Okundu tikları
class ChatDetailView extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;

  const ChatDetailView({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _messagesSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  // Dark theme renkleri
  static const Color _otherBubbleColor = Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // İlk mesajları yükle
      final messages = await _supabaseService.getMessageHistory(
        _currentUserId!,
        widget.otherUserId,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();

      // Realtime stream'i başlat
      _startRealtimeListener();

      // Mesajları okundu olarak işaretle
      _markMessagesAsRead();
    } catch (e) {
      print('❌ Chat yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Bağlantı hatası: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startRealtimeListener() {
    if (_currentUserId == null) return;

    _messagesSubscription = _supabaseService
        .getMessagesStream(_currentUserId!, widget.otherUserId)
        .listen((messages) {
          if (mounted) {
            setState(() => _messages = messages);
            _scrollToBottom();
            _markMessagesAsRead();
          }
        });
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    await _supabaseService.markMessagesAsRead(
      widget.otherUserId,
      _currentUserId!,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    _messageController.clear();

    try {
      final success = await _supabaseService.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.otherUserId,
        content: content,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj gönderilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Mesaj gönderme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.arkaplanKoyu,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.morVurgu),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.arkaplanAcik,
      foregroundColor: AppTheme.metinAna,
      elevation: 0,
      leadingWidth: 40,
      title: Row(
        children: [
          // Avatar with gradient border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.anaGradient,
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              backgroundColor: AppTheme.kartArkaplani,
              child: widget.otherUserAvatar == null
                  ? Text(
                      (widget.otherUserName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.metinAna,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.metinAna,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'çevrimiçi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.metinIkincil,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final reversedIndex = _messages.length - 1 - index;
        final message = _messages[reversedIndex];
        final isMe = message['sender_id'] == _currentUserId;
        final showDate = _shouldShowDate(reversedIndex);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message['created_at']),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;
    final current = DateTime.parse(_messages[index]['created_at']);
    final previous = DateTime.parse(_messages[index - 1]['created_at']);
    return current.day != previous.day;
  }

  Widget _buildDateDivider(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    String text;

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      text = 'Bugün';
    } else if (date.day == now.day - 1 && date.month == now.month) {
      text = 'Dün';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.kartArkaplani,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.metinIkincil),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final isRead = message['is_read'] ?? false;
    final time = DateTime.parse(message['created_at']).toLocal();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.anaGradient : null,
          color: isMe ? null : _otherBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppTheme.morVurgu.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['content'] ?? '',
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AppTheme.metinSoluk,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: isRead
                        ? const Color(0xFF4FC3F7)
                        : Colors.white.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bağlantı Hatası',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.metinAna,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.anaGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton.icon(
                onPressed: _initializeChat,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.morVurgu.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppTheme.morVurgu.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz mesaj yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.metinAna,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sohbete başlamak için bir mesaj gönderin',
            style: TextStyle(fontSize: 14, color: AppTheme.metinIkincil),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.arkaplanAcik,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.kartArkaplani,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.attach_file,
                  color: AppTheme.metinIkincil,
                ),
                onPressed: () {
                  // TODO: Dosya ekleme
                },
              ),
            ),

            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.kartArkaplani,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.kenarRengi.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Emoji button
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: AppTheme.metinIkincil,
                      ),
                      onPressed: () {
                        // TODO: Emoji picker
                      },
                    ),

                    // TextField
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppTheme.metinAna),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Enter Text',
                          hintStyle: TextStyle(color: AppTheme.metinSoluk),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button with gradient
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.anaGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.morVurgu.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
