import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_provider.dart';

/// Admin Panel - Tüm Kullanıcılar Listesi (Supabase Native)
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // users tablosundan tüm kullanıcıları çek
      final response = await _supabase
          .from('users')
          .select(
            'id, username, email, avatar_url, first_name, last_name, is_online, is_admin, created_at',
          )
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Kullanıcıları yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;

    return _users.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return username.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchBar(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredUsers.isEmpty
            ? _buildEmptyState()
            : _buildUsersList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Kullanıcı ara...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Kullanıcı bulunamadı'
                : 'Arama sonucu bulunamadı',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'] ?? 'Bilinmeyen';
    final email = user['email'] ?? '';
    final avatarUrl = user['avatar_url'];
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final isOnline = user['is_online'] ?? false;
    final isAdmin = user['is_admin'] ?? false;
    final createdAt = DateTime.tryParse(user['created_at'] ?? '');

    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : username;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Online indicator
            if (isOnline)
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
        title: Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@$username',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (createdAt != null)
              Text(
                'Katılım: ${_formatDate(createdAt)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleUserAction(action, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Profili Görüntüle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Kullanıcıyı Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        // TODO: Navigate to profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil görüntüleme: ${user['username']}')),
        );
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final username = user['username'] ?? 'Kullanıcı';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text(
          '$username kullanıcısını silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userId = user['id'];

        // Supabase'den kullanıcıyı sil
        await _supabase.from('users').delete().eq('id', userId);

        // Listeyi yenile
        _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$username silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Kullanıcı silme hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
