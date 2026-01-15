import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'chat_detail_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final conversations = await _supabaseService.getConversations(userId);
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Load conversations error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlarım 💬')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final message = _conversations[index];
                return _buildConversationItem(message);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Henüz mesajın yok', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Arkadaşlarına mesaj göndererek başla!'),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> message) {
    final currentUserId = _supabaseService.client.auth.currentUser?.id;
    final isMe = message['sender_id'] == currentUserId;

    // Konuşulan kişi bilgisi (ben gönderdiysem alıcı, o gönderdiyse gönderen)
    final otherUser = isMe ? message['receiver'] : message['sender'];

    // Null check
    if (otherUser == null) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: otherUser['avatar_url'] != null
            ? NetworkImage(otherUser['avatar_url'])
            : null,
        child: otherUser['avatar_url'] == null
            ? Text((otherUser['username'] ?? 'U')[0].toUpperCase())
            : null,
      ),
      title: Text(
        otherUser['username'] ?? 'Kullanıcı',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        isMe ? 'Sen: ${message['content']}' : message['content'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: message['is_read'] == false && !isMe
              ? Colors.black87
              : Colors.grey[600],
          fontWeight: message['is_read'] == false && !isMe
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(message['created_at']),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          if (message['is_read'] == false && !isMe)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailView(
              otherUserId: otherUser['id'],
              otherUserAvatar: otherUser['avatar_url'],
              otherUserName: otherUser['username'],
            ),
          ),
        );
        _loadConversations(); // Geri dönünce listeyi yenile
      },
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}
