import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/friendship_service.dart';
import 'profile_screen.dart';

/// Keşfet Ekranı - Diğer kullanıcıları keşfet ve arkadaşlık isteği gönder
class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final SupabaseService _supabaseService = SupabaseService();
  final FriendshipService _friendshipService = FriendshipService();

  List<Map<String, dynamic>> _users = [];
  Map<String, String> _friendshipStatuses = {}; // userId -> status
  bool _isLoading = true;
  String _searchQuery = '';
  String? _currentUserId;

  // Tema renkleri
  static const Color _primaryColor = Color(0xFF667eea);
  static const Color _secondaryColor = Color(0xFF764ba2);

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = _searchQuery.isEmpty
          ? await _supabaseService.getAllUsers()
          : await _supabaseService.searchUsers(_searchQuery);

      // Her kullanıcı için arkadaşlık durumunu kontrol et
      await _loadFriendshipStatuses(users);

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Load users error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFriendshipStatuses(List<Map<String, dynamic>> users) async {
    if (_currentUserId == null) return;

    Map<String, String> statuses = {};
    for (var user in users) {
      final userId = user['id'];
      if (userId == null) continue;

      final status = await _supabaseService.getFriendshipStatus(
        _currentUserId!,
        userId,
      );

      if (status != null) {
        statuses[userId] = status['status'] ?? 'none';
      } else {
        statuses[userId] = 'none';
      }
    }

    _friendshipStatuses = statuses;
  }

  Future<void> _sendFriendRequest(String toUserId) async {
    if (_currentUserId == null) return;

    try {
      final success = await _friendshipService.sendFriendRequest(
        fromUserId: _currentUserId!,
        toUserId: toUserId,
      );

      if (success) {
        setState(() {
          _friendshipStatuses[toUserId] = 'pending_sent';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arkadaşlık isteği gönderildi! ✓'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
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
        title: const Text(
          'Keşfet 🌍',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadUsers();
              },
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _users.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadUsers,
              color: _primaryColor,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return _buildUserCard(user);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Kullanıcı bulunamadı 😕',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir arama deneyin',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'] ?? '';
    final username = user['username'] ?? 'Kullanıcı';
    final city = user['city'] ?? '';
    final avatarUrl = user['avatar_url'];
    final status = _friendshipStatuses[userId] ?? 'none';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: userId, isCurrentUser: false),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Avatar
            Hero(
              tag: 'avatar_$userId',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Username
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // City
            if (city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 2),
                  Text(
                    city,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActionButton(userId, status),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String userId, String status) {
    switch (status) {
      case 'accepted':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text(
                'Arkadaşsınız',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );

      case 'pending_sent':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 6),
              Text(
                'İstek Gönderildi',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );

      case 'pending_received':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                'İstek Bekliyor',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );

      default: // 'none'
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _sendFriendRequest(userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 16),
                SizedBox(width: 6),
                Text(
                  'Arkadaş Ekle',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        );
    }
  }
}
