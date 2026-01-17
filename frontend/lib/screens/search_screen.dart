import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_provider.dart';
import '../services/friendship_service.dart';
import 'chat_screen.dart';

/// Kullanıcı Arama & Keşfet Ekranı
/// Modern, Instagram-style UI
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendshipService _friendshipService = FriendshipService();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, String?> _friendshipStatuses = {}; // user_id -> status
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final auth = ref.read(authProvider);
    final currentUserId = auth.userId; // Supabase UUID

    if (currentUserId == null) return;

    try {
      final results = await _friendshipService.searchUsers(
        query: query,
        currentUserId: currentUserId,
      );

      // Her kullanıcı için ilişki durumunu kontrol et
      Map<String, String?> statuses = {};
      for (var user in results) {
        final status = await _friendshipService.checkFriendshipStatus(
          currentUserId: currentUserId,
          otherUserId: user['id'],
        );
        statuses[user['id']] = status;
      }

      setState(() {
        _searchResults = results;
        _friendshipStatuses = statuses;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.userId; // Supabase UUID
    if (currentUserId == null) return;

    try {
      final success = await _friendshipService.sendFriendRequest(
        fromUserId: currentUserId,
        toUserId: userId,
      );

      if (success) {
        setState(() {
          _friendshipStatuses[userId] = 'pending_sent';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arkadaşlık isteği gönderildi ✓'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İstek gönderilemedi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Keşfet'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Modern Arama Çubuğu
          _buildSearchBar(),

          // Sonuçlar
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Kullanıcı ara...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
          onChanged: (value) {
            setState(() {}); // Suffix icon güncellemesi için
            if (value.length >= 2) {
              // Debounce için
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  _performSearch(value);
                }
              });
            }
          },
          onSubmitted: _performSearch,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState(
        icon: Icons.explore_outlined,
        title: 'Kullanıcı Ara',
        subtitle: 'İsim veya kullanıcı adı ile arayın',
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search,
        title: 'Kullanıcı Bulunamadı',
        subtitle: 'Farklı bir arama deneyin',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey[200],
        indent: 80,
      ),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final friendshipStatus = _friendshipStatuses[user['id']];
        return _buildUserTile(user, friendshipStatus);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, String? friendshipStatus) {
    final username = user['username'] ?? 'Unknown';
    final bio = user['bio'] ?? '';
    final avatarUrl = user['avatar_url'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar (büyük, yuvarlak)
          Hero(
            tag: 'avatar_${user['id']}',
            child: CircleAvatar(
              radius: 30,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              backgroundColor: const Color(0xFF667eea),
              child: avatarUrl == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Kullanıcı Bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Aksiyon Butonu (Duruma Göre)
          _buildActionButton(user['id'], friendshipStatus),
        ],
      ),
    );
  }

  Widget _buildActionButton(String userId, String? friendshipStatus) {
    switch (friendshipStatus) {
      case 'friends':
        // Arkadaşız - Mesaj butonu
        return _buildMessageButton(userId);

      case 'pending_sent':
        // İstek gönderdim - Devre dışı buton
        return _buildPendingButton();

      case 'pending_received':
        // Bana istek gelmiş - Kabul et butonu
        return _buildAcceptButton(userId);

      default:
        // İlişki yok - Ekle butonu
        return _buildAddButton(userId);
    }
  }

  Widget _buildAddButton(String userId) {
    return ElevatedButton.icon(
      onPressed: () => _sendFriendRequest(userId),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
      icon: const Icon(Icons.person_add, size: 18),
      label: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPendingButton() {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[400]!),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        'İstek Gönderildi',
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildAcceptButton(String userId) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Accept request
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        'Kabul Et',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMessageButton(String userId) {
    final user = _searchResults.firstWhere((u) => u['id'] == userId);

    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              friendId: userId,
              friendName: user['username'] ?? 'User',
              friendAvatar: user['avatar_url'],
            ),
          ),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.message, color: Colors.green, size: 20),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
