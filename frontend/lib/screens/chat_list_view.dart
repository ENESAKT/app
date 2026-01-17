import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/app_theme.dart';
import '../services/auth_provider.dart';
import '../services/supabase_service.dart';
import 'chat_detail_view.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MESAJLAR LİSTESİ EKRANI - Dark Theme
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Özellikler:
/// - Arama çubuğu (Search in message)
/// - Filtre butonları (All, Contacts, Finance, Unknown)
/// - Konuşma listesi (avatar, isim, son mesaj, saat, okunmamış badge)
/// - Start Chat FAB butonu
/// - Dark theme (#121212 arka plan)
/// - Mor-Turuncu gradient vurgular
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  // Filter options
  final List<String> _filters = ['All', 'Contacts', 'Finance', 'Unknown'];

  @override
  void initState() {
    super.initState();
    // Türkçe timeago ayarı
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = auth.userId;

    if (_currentUserId != null) {
      _loadData();
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_friends);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((friend) {
        final username = (friend['username'] ?? '').toString().toLowerCase();
        final firstName = (friend['first_name'] ?? '').toString().toLowerCase();
        final lastName = (friend['last_name'] ?? '').toString().toLowerCase();
        return username.contains(_searchQuery) ||
            firstName.contains(_searchQuery) ||
            lastName.contains(_searchQuery);
      }).toList();
    }

    // Category filter (şimdilik sadece All çalışıyor)
    // TODO: Finance, Unknown kategorileri için backend desteği gerekli

    _filteredConversations = result;
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
        _applyFilters();
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

  /// Okunmamış mesaj sayısını hesapla
  int _getUnreadCount(String friendId) {
    return _conversations.where((conv) {
      return conv['sender_id'] == friendId &&
          conv['receiver_id'] == _currentUserId &&
          conv['is_read'] == false;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.arkaplanKoyu,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            _buildHeader(),

            // Filter chips
            _buildFilterChips(),

            // Conversation list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.morVurgu,
                      ),
                    )
                  : _filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.morVurgu,
                      child: _buildConversationList(),
                    ),
            ),
          ],
        ),
      ),
      // Start Chat FAB
      floatingActionButton: _buildStartChatFAB(),
    );
  }

  /// Header with search bar and profile
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(color: AppTheme.arkaplanKoyu),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mesajlar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.metinAna,
                ),
              ),
              // Profile avatar
              FutureBuilder<Map<String, dynamic>?>(
                future: _supabaseService.getCurrentUser(),
                builder: (context, snapshot) {
                  final avatarUrl = snapshot.data?['avatar_url'];
                  final username = snapshot.data?['username'] ?? 'U';
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.anaGradient,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.arkaplanAcik,
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              username[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.metinAna,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.arkaplanAcik,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.kenarRengi.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.metinAna),
              decoration: InputDecoration(
                hintText: 'Search in message',
                hintStyle: TextStyle(color: AppTheme.metinSoluk),
                prefixIcon: Icon(Icons.search, color: AppTheme.metinSoluk),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: AppTheme.metinSoluk),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter chips row
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _applyFilters();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.anaGradient : null,
                color: isSelected ? null : AppTheme.kartArkaplani,
                borderRadius: BorderRadius.circular(25),
                border: !isSelected
                    ? Border.all(color: AppTheme.kenarRengi.withOpacity(0.5))
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.morVurgu.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.metinIkincil,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Empty state widget
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
            'Henüz mesajınız yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.metinAna,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki butona tıklayarak sohbet başlatın!',
            style: TextStyle(fontSize: 14, color: AppTheme.metinIkincil),
          ),
        ],
      ),
    );
  }

  /// Conversation list
  Widget _buildConversationList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final friend = _filteredConversations[index];
        return _buildConversationTile(friend);
      },
    );
  }

  /// Single conversation tile
  Widget _buildConversationTile(Map<String, dynamic> friend) {
    final friendId = friend['id'] ?? '';
    final username = friend['username'] ?? 'Kullanıcı';
    final firstName = friend['first_name'] ?? '';
    final lastName = friend['last_name'] ?? '';
    final displayName = firstName.isNotEmpty
        ? '$firstName $lastName'.trim()
        : username;
    final avatarUrl = friend['avatar_url'];

    // Son mesajı bul
    final lastMessage = _getLastMessage(friendId);
    final hasMessage = lastMessage != null;
    final unreadCount = _getUnreadCount(friendId);

    String previewText = 'Sohbete başla...';
    DateTime? createdAt;
    bool isMine = false;

    if (hasMessage) {
      final content = lastMessage['content'] ?? '';
      createdAt = DateTime.parse(lastMessage['created_at']);
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
              otherUserName: displayName,
              otherUserAvatar: avatarUrl,
            ),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: unreadCount > 0
              ? AppTheme.morVurgu.withOpacity(0.08)
              : AppTheme.arkaplanAcik,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unreadCount > 0
                ? AppTheme.morVurgu.withOpacity(0.3)
                : AppTheme.kenarRengi.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar with gradient border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unreadCount > 0 ? AppTheme.anaGradient : null,
                border: unreadCount == 0
                    ? Border.all(color: AppTheme.kenarRengi, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.kartArkaplani,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.metinAna,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Message info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.metinAna,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? AppTheme.morVurgu
                                : AppTheme.metinSoluk,
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
                            color: unreadCount > 0
                                ? AppTheme.metinAna
                                : AppTheme.metinIkincil,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Unread badge
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Şimdi';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}dk';
    } else if (diff.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return timeago.format(dateTime, locale: 'tr');
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  /// Start Chat FAB
  Widget _buildStartChatFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.anaGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.morVurgu.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showUserSelectionModal,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Start Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show user selection modal for starting new chat
  void _showUserSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserSelectionModal(
        friends: _friends,
        onUserSelected: (user) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailView(
                otherUserId: user['id'],
                otherUserName: user['username'] ?? 'Kullanıcı',
                otherUserAvatar: user['avatar_url'],
              ),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// USER SELECTION MODAL - Yeni Sohbet Başlatma
/// ═══════════════════════════════════════════════════════════════════════════
class _UserSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final Function(Map<String, dynamic>) onUserSelected;

  const _UserSelectionModal({
    required this.friends,
    required this.onUserSelected,
  });

  @override
  State<_UserSelectionModal> createState() => _UserSelectionModalState();
}

class _UserSelectionModalState extends State<_UserSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _filteredFriends = widget.friends;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = widget.friends;
      } else {
        _filteredFriends = widget.friends.where((friend) {
          final username = (friend['username'] ?? '').toString().toLowerCase();
          return username.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.arkaplanAcik,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.kenarRengi,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yeni Sohbet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.metinAna,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.metinIkincil),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.kartArkaplani,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.metinAna),
                decoration: InputDecoration(
                  hintText: 'Arkadaş ara...',
                  hintStyle: TextStyle(color: AppTheme.metinSoluk),
                  prefixIcon: Icon(Icons.search, color: AppTheme.metinSoluk),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Friends list
          Expanded(
            child: _filteredFriends.isEmpty
                ? Center(
                    child: Text(
                      'Arkadaş bulunamadı',
                      style: TextStyle(color: AppTheme.metinIkincil),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      return _buildFriendTile(friend);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final username = friend['username'] ?? 'Kullanıcı';
    final avatarUrl = friend['avatar_url'];

    return ListTile(
      onTap: () => widget.onUserSelected(friend),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.anaGradient,
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.kartArkaplani,
          backgroundImage: avatarUrl != null
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl == null
              ? Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.metinAna,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        username,
        style: const TextStyle(
          color: AppTheme.metinAna,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.morVurgu.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          color: AppTheme.morVurgu,
          size: 20,
        ),
      ),
    );
  }
}
