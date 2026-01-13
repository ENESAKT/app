import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../services/friendship_service.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// HomeScreen - Ana sayfa
///
/// Özellikler:
/// - Aktif kullanıcılar (Story bar)
/// - Son konuşmalar listesi
/// - Okunmamış mesaj rozetleri
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final FriendshipService _friendshipService = FriendshipService();

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  String? _currentUserId;

  // Renk paleti (Telegram mavisi tonları)
  static const Color _primaryColor = Color(0xFF0088CC);
  static const Color _accentColor = Color(0xFF00A8E8);
  static const Color _backgroundColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final conversations = await _chatService.getConversations();
      final friends = await _friendshipService.getFriends(
        userId: _currentUserId ?? '',
      );

      setState(() {
        _conversations = conversations;
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Veri yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Story Bar (Aktif Kullanıcılar)
                  SliverToBoxAdapter(child: _buildStoryBar()),

                  // Konuşmalar Başlığı
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Mesajlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),

                  // Konuşma Listesi
                  _conversations.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildConversationTile(_conversations[index]),
                            childCount: _conversations.length,
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      title: const Text(
        'FriendApp',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryBar() {
    if (_friends.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 110,
      color: _cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          final isOnline = friend['is_online'] ?? false;

          return GestureDetector(
            onTap: () => _openChat(friend),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  // Avatar with online indicator
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isOnline
                                ? [_accentColor, _primaryColor]
                                : [Colors.grey[300]!, Colors.grey[400]!],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage: friend['avatar_url'] != null
                                ? NetworkImage(friend['avatar_url'])
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: friend['avatar_url'] == null
                                ? Text(
                                    (friend['username'] ?? 'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Username
                  Text(
                    friend['username'] ?? 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final otherUser = conversation['other_user'] ?? {};
    final lastMessage = conversation['last_message'] ?? {};
    final unreadCount = conversation['unread_count'] ?? 0;
    final isRead = lastMessage['is_read'] ?? true;
    final isMine = lastMessage['sender_id'] == _currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openChat(otherUser),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: otherUser['avatar_url'] != null
                  ? NetworkImage(otherUser['avatar_url'])
                  : null,
              backgroundColor: _primaryColor.withOpacity(0.1),
              child: otherUser['avatar_url'] == null
                  ? Text(
                      (otherUser['username'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    )
                  : null,
            ),
            if (otherUser['is_online'] == true)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          otherUser['username'] ?? 'Kullanıcı',
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            // Çift tik ikonu
            if (isMine) ...[
              Icon(
                Icons.done_all,
                size: 16,
                color: isRead ? _primaryColor : Colors.grey,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                lastMessage['content'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                  fontWeight: unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(lastMessage['created_at']),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? _primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Henüz mesaj yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Arkadaş ekleyerek sohbete başla',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            icon: const Icon(Icons.person_add),
            label: const Text('Arkadaş Bul'),
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      backgroundColor: _primaryColor,
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  void _openChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          friendId: user['id'],
          friendName: user['username'] ?? 'Kullanıcı',
          friendAvatar: user['avatar_url'],
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Şimdi';
      if (diff.inHours < 1) return '${diff.inMinutes}dk';
      if (diff.inDays < 1) return '${diff.inHours}sa';
      if (diff.inDays < 7) return '${diff.inDays}g';
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}
