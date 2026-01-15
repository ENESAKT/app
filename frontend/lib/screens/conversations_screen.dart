import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/auth_provider.dart';
import '../services/supabase_service.dart';
import 'chat_detail_view.dart';

/// Konuşmalar listesi ekranı - Sadece arkadaşları gösterir
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _friends = []; // Kabul edilmiş arkadaşlar
  List<Map<String, dynamic>> _conversations = []; // Son mesajlar
  bool _isLoading = true;
  String? _currentUserId;

  // Tema renkleri
  static const Color _primaryColor = Color(0xFF667eea);
  static const Color _secondaryColor = Color(0xFF764ba2);

  @override
  void initState() {
    super.initState();
    // Türkçe timeago ayarı
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = auth.userId; // Supabase UUID

    if (_currentUserId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Kabul edilmiş arkadaşları yükle
      final friends = await _supabaseService.getAcceptedFriends(
        _currentUserId!,
      );

      // 2. Son konuşmaları yükle
      final conversations = await _supabaseService.getConversations(
        _currentUserId!,
      );

      setState(() {
        _friends = friends;
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Load data error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Arkadaşla son mesajı bul
  Map<String, dynamic>? _getLastMessage(String friendId) {
    try {
      return _conversations.firstWhere((conv) {
        final senderId = conv['sender_id'];
        final receiverId = conv['receiver_id'];
        return (senderId == friendId && receiverId == _currentUserId) ||
            (senderId == _currentUserId && receiverId == friendId);
      });
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Sohbetler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // TODO: Yeni sohbet başlat modalı
            },
            tooltip: 'Yeni Sohbet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _friends.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _primaryColor,
              child: _buildFriendsList(),
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
            'Henüz arkadaşınız yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keşfet sayfasından arkadaş ekleyin!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Ana sayfadaki Keşfet sekmesine git
            },
            icon: const Icon(Icons.explore),
            label: const Text('Keşfete Git'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendTile(friend);
      },
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final friendId = friend['id'] ?? '';
    final username = friend['username'] ?? 'Kullanıcı';
    final avatarUrl = friend['avatar_url'];

    // Son mesajı bul
    final lastMessage = _getLastMessage(friendId);
    final hasMessage = lastMessage != null;

    String previewText = 'Sohbete başla...';
    DateTime? createdAt;
    bool isRead = true;
    bool isMine = false;

    if (hasMessage) {
      final content = lastMessage['content'] ?? '';
      createdAt = DateTime.parse(lastMessage['created_at']);
      isRead = lastMessage['is_read'] ?? true;
      isMine = lastMessage['sender_id'] == _currentUserId;
      previewText = isMine ? 'Sen: $content' : content;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              otherUserId: friendId,
              otherUserName: username,
              otherUserAvatar: avatarUrl,
            ),
          ),
        ).then((_) => _loadData()); // Geri dönünce yenile
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: !isRead && !isMine ? Colors.blue.shade50 : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar with gradient border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Mesaj bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontWeight: !isRead && !isMine
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          timeago.format(createdAt, locale: 'tr'),
                          style: TextStyle(
                            fontSize: 12,
                            color: !isRead && !isMine
                                ? _primaryColor
                                : Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: !isRead && !isMine
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: !isRead && !isMine
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (!isRead && !isMine) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryColor, _secondaryColor],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
