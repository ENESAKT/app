import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'user_profile_view.dart';
import 'chat_detail_view.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = []; // Arama sonucu gösterilecekler

  // Arkadaşlık durumu cache (userId -> status)
  // O(1) lookup için Map kullanıyoruz
  final Map<String, String> _friendshipStatusCache = {};
  final Map<String, dynamic> _friendshipIdCache =
      {}; // Kabul için ID gerekli (int veya String olabilir)

  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) {
          final name = user.displayName.toLowerCase();
          final city = (user.city ?? '').toLowerCase();
          return name.contains(query) || city.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Tüm kullanıcıları getir (Kendim hariç)
      final usersData = await _supabaseService.getAllUsers();
      final users = usersData.map((e) => UserModel.fromJson(e)).toList();

      // 2. Arkadaşlık durumlarını getir ve cache'e yükle
      final friendships = await _supabaseService.getMyFriendships(
        _currentUserId!,
      );

      // Cache'i temizle ve yeniden doldur
      _friendshipStatusCache.clear();
      _friendshipIdCache.clear();

      for (final f in friendships) {
        final u1 = f['user_id_1'];
        final u2 = f['user_id_2'];
        final status = f['status'];
        final requestedBy = f['requested_by'];
        final id = f['id'];

        // Karşı tarafın ID'sini bul
        final otherUserId = (u1 == _currentUserId) ? u2 : u1;

        // Durumu belirle
        String friendshipStatus;
        if (status == 'accepted') {
          friendshipStatus = 'accepted';
        } else if (status == 'pending') {
          friendshipStatus = (requestedBy == _currentUserId)
              ? 'pending_sent'
              : 'pending_received';
        } else {
          friendshipStatus = 'none';
        }

        // Cache'e ekle
        _friendshipStatusCache[otherUserId] = friendshipStatus;
        _friendshipIdCache[otherUserId] = id;
      }

      if (mounted) {
        // Kendi profilimi listeden filtrele
        final filteredList = users
            .where((u) => u.id != _currentUserId)
            .toList();
        setState(() {
          _allUsers = filteredList;
          _filteredUsers = filteredList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Discover data fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Bir kullanıcıyla olan arkadaşlık durumunu bul (O(1) cache lookup)
  /// Return: 'none', 'pending_sent', 'pending_received', 'accepted'
  String _getFriendshipStatus(String otherUserId) {
    return _friendshipStatusCache[otherUserId] ?? 'none';
  }

  /// Arkadaşlık ID'sini cache'den getir (kabul işlemi için)
  int? _getFriendshipId(String otherUserId) {
    return _friendshipIdCache[otherUserId];
  }

  Future<void> _handleFriendAction(UserModel user, String status) async {
    if (_currentUserId == null) return;

    // pending_sent ise işlem yok (disabled buton)
    if (status == 'pending_sent') return;

    try {
      if (status == 'none') {
        // İstek gönder
        final success = await _supabaseService.sendFriendRequest(
          _currentUserId!,
          user.id,
        );
        if (success) {
          // Local update
          await _fetchData(); // Basit refresh, idealde listeyi manipüle ederdik
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.displayName}\'e istek gönderildi')),
          );
        }
      } else if (status == 'pending_received') {
        // İsteği kabul et - Cache'den friendship ID'yi al
        final friendshipId = _getFriendshipId(user.id);

        if (friendshipId != null) {
          final success = await _supabaseService.acceptFriendRequest(
            friendshipId.toString(), // String'e çevir
          );
          if (success) {
            await _fetchData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artık arkadaşsınız!')),
            );
          }
        } else {
          print('⚠️ Friendship ID bulunamadı: ${user.id}');
        }
      } else if (status == 'accepted') {
        // Sohbete git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              otherUserId: user.id,
              otherUserName: user.displayName,
              otherUserAvatar: user.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      print('Action error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bir hata oluştu')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Hafif gri arka plan
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Yeni arkadaşlar bul...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),

            // Grid Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 sütun
                              childAspectRatio:
                                  0.75, // Dikey dikdörtgen kartlar
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_filteredUsers[index]);
                        },
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
          Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Kullanıcı bulunamadı',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veritabanını kontrol edin.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final status = _getFriendshipStatus(user.id);

    return GestureDetector(
      onTap: () {
        // Profil detayına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileView(userId: user.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Köşeleri kırp
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Profil Resmi (Cover) - Null safety ile
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.blueGrey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blueGrey[100],
                  child: const Center(
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
              )
            else
              Container(
                color: Colors.blueGrey[100],
                child: const Center(
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),

            // 2. Siyah Gradient (Altta)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120, // Gradient yüksekliği
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7), // Koyu siyah
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // 3. İsim ve Bilgiler (Gradient üstüne)
            Positioned(
              left: 12,
              bottom: 12,
              right: 60, // Buton için boşluk
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.age != null
                        ? '${user.displayName}, ${user.age}'
                        : user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (user.city != null && user.city!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.city!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 4. Aksiyon Butonu (Sağ Alt)
            Positioned(
              right: 10,
              bottom: 10,
              child: _buildActionButton(user, status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(UserModel user, String status) {
    IconData icon;
    Color color;
    bool disabled = false;

    switch (status) {
      case 'accepted':
        icon = Icons.message_rounded; // Sohbete git
        color = Colors.blue;
        break;
      case 'pending_received':
        icon = Icons.check_circle_outline; // İsteği kabul et
        color = Colors.green;
        break;
      case 'pending_sent':
        icon = Icons.hourglass_empty; // Beklemede (pasif)
        color = Colors.grey;
        disabled = true;
        break;
      case 'none':
      default:
        icon = Icons.person_add_rounded; // Arkadaş ekle
        color = Colors.white;
        break;
    }

    // Eğer none/add ise, buton daha belirgin olsun diye farklı style
    if (status == 'none') {
      return SizedBox(
        width: 40,
        height: 40,
        child: FloatingActionButton(
          heroTag: 'action_${user.id}',
          onPressed: () => _handleFriendAction(user, status),
          backgroundColor: Colors.white,
          mini: true,
          elevation: 2,
          child: const Icon(Icons.person_add_rounded, color: Colors.black),
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: FloatingActionButton(
        heroTag: 'action_${user.id}',
        onPressed: disabled ? null : () => _handleFriendAction(user, status),
        backgroundColor: disabled
            ? Colors.white.withOpacity(0.8)
            : Colors.white,
        mini: true,
        elevation: 2,
        child: Icon(icon, color: disabled ? Colors.grey : color),
      ),
    );
  }
}
