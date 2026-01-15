import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final userData = await _supabaseService.getUser(widget.userId);
    if (mounted) {
      setState(() {
        if (userData != null) {
          _user = UserModel.fromJson(userData);
        }
        _isLoading = false;
      });
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

    return Scaffold(
      backgroundColor: Colors.white,
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
