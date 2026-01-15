import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'chat_detail_view.dart';

class UserProfileView extends StatefulWidget {
  final String userId;

  const UserProfileView({super.key, required this.userId});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  UserModel? _user;
  String? _currentUserId;
  String _friendshipStatus =
      'none'; // 'none', 'pending_sent', 'pending_received', 'accepted'
  int? _friendshipId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchUserAndFriendship();
  }

  Future<void> _fetchUserAndFriendship() async {
    setState(() => _isLoading = true);

    try {
      // 1. Kullanıcı verisini çek
      final userData = await _supabaseService.getUser(widget.userId);
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }

      // 2. Arkadaşlık durumunu kontrol et
      if (_currentUserId != null && widget.userId != _currentUserId) {
        await _checkFriendshipStatus();
      }
    } catch (e) {
      print('Proflle fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFriendshipStatus() async {
    if (_currentUserId == null) return;

    try {
      final friendships = await _supabaseService.getMyFriendships(
        _currentUserId!,
      );

      final friendship = friendships.firstWhere((f) {
        final u1 = f['user_id_1'];
        final u2 = f['user_id_2'];
        return (u1 == _currentUserId && u2 == widget.userId) ||
            (u1 == widget.userId && u2 == _currentUserId);
      }, orElse: () => {});

      if (friendship.isNotEmpty) {
        final status = friendship['status'];
        final requestedBy = friendship['requested_by'];
        _friendshipId = friendship['id'];

        if (status == 'accepted') {
          _friendshipStatus = 'accepted';
        } else if (status == 'pending') {
          _friendshipStatus = requestedBy == _currentUserId
              ? 'pending_sent'
              : 'pending_received';
        }
      } else {
        _friendshipStatus = 'none';
      }
    } catch (e) {
      print('Friendship check error: $e');
    }
  }

  Future<void> _handleAction() async {
    if (_currentUserId == null || _user == null) return;

    try {
      if (_friendshipStatus == 'none') {
        // Arkadaşlık isteği gönder
        final success = await _supabaseService.sendFriendRequest(
          _currentUserId!,
          widget.userId,
        );
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_user!.displayName}\'e istek gönderildi'),
            ),
          );
          await _checkFriendshipStatus(); // Durumu güncelle
          setState(() {});
        }
      } else if (_friendshipStatus == 'pending_received') {
        // İsteği kabul et
        if (_friendshipId != null) {
          final success = await _supabaseService.acceptFriendRequest(
            _friendshipId!,
          );
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artık arkadaşsınız!')),
            );
            await _checkFriendshipStatus(); // Durumu güncelle
            setState(() {});
          }
        }
      } else if (_friendshipStatus == 'accepted') {
        // Mesajlaşmaya git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              otherUserId: _user!.id,
              otherUserName: _user!.displayName,
              otherUserAvatar: _user!.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bir işlem hatası oluştu')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Kullanıcı bulunamadı")),
      );
    }

    final bool isMe = _currentUserId == widget.userId;

    IconData fabIcon = Icons.add;
    Color fabColor = Colors.black;
    String label = '';

    if (!isMe) {
      switch (_friendshipStatus) {
        case 'accepted':
          fabIcon = Icons.chat;
          fabColor = Colors.blue;
          label = 'Mesaj Gönder';
          break;
        case 'pending_received':
          fabIcon = Icons.check;
          fabColor = Colors.green;
          label = 'Kabul Et';
          break;
        case 'pending_sent':
          fabIcon = Icons.hourglass_empty;
          fabColor = Colors.grey;
          label = 'İstek Gönderildi';
          break;
        case 'none':
        default:
          fabIcon = Icons.person_add;
          fabColor = Colors.blueAccent;
          label = 'Arkadaş Ekle';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: !isMe
          ? FloatingActionButton.extended(
              onPressed: _friendshipStatus == 'pending_sent'
                  ? null
                  : _handleAction,
              backgroundColor: _friendshipStatus == 'pending_sent'
                  ? Colors.grey
                  : fabColor,
              icon: Icon(fabIcon, color: Colors.white),
              label: Text(label, style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // 1. Büyük Profil Fotoğrafı (SliverAppBar)
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: _user!.avatarUrl != null
                  ? Image.network(_user!.avatarUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
              title: Text(
                _user!.displayName,
                style: const TextStyle(
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              centerTitle: true,
            ),
          ),

          // 2. Detaylar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İsim ve Yaş/Şehir
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!.displayName.isNotEmpty
                                  ? _user!.displayName
                                  : _user!.username,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_user!.age != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_user!.age} Yaş',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (_user!.age != null)
                                  const SizedBox(width: 8),
                                if (_user!.city != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.orange[800],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _user!.city!,
                                          style: TextStyle(
                                            color: Colors.orange[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Hakkımda
                  const Text(
                    "Hakkımda",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user!.bio ?? "Henüz bir biyografi eklenmemiş.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // İlgi Alanları
                  if (_user!.interests != null &&
                      _user!.interests!.isNotEmpty) ...[
                    const Text(
                      "İlgi Alanları",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _user!.interests!.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 100), // Alt boşluk
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
