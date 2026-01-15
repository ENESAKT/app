import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Sohbet Detay Ekranı - Realtime mesajlaşma
///
/// Özellikler:
/// - Supabase Realtime Stream ile anlık mesaj akışı
/// - Bubble UI: Benim mesajlarım sağda (gradient), karşı tarafınki solda (gri)
/// - Reverse ListView (klavye açıldığında otomatik scroll)
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
  String? _errorMessage; // Hata mesajı için
  String? _currentUserId;

  // Tema renkleri
  static const Color _primaryColor = Color(0xFF667eea);
  static const Color _secondaryColor = Color(0xFF764ba2);
  static const Color _myBubbleColor = Color(0xFF667eea);
  static const Color _otherBubbleColor = Color(0xFFE8E8EE);
  static const Color _backgroundColor = Color(0xFFF5F6FA);

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
      _errorMessage = null; // Önceki hatayı temizle
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
          0, // Reverse list olduğu için 0 en alta gider
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
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
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
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 30,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.otherUserAvatar != null
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            backgroundColor: Colors.white24,
            child: widget.otherUserAvatar == null
                ? Text(
                    (widget.otherUserName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
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
                  ),
                ),
                const Text(
                  'çevrimiçi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Menu options
          },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // En son mesaj altta görünür
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // Reverse list olduğu için indexi tersine çevir
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
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
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
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : _otherBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['content'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: isRead ? Colors.lightBlueAccent : Colors.white60,
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
            Text(
              'Bağlantı Hatası',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeChat,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: _primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz mesaj yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sohbete başlamak için bir mesaj gönderin',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji button
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: Colors.grey[600],
              ),
              onPressed: () {},
            ),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yazın...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
