import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_provider.dart';

/// Engellenmiş Kullanıcılar Ekranı - Supabase Native
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.userId;

    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // blocked_users tablosundan veri çek
      // Join ile engellenen kullanıcının detaylarını al
      final response = await _supabase
          .from('blocked_users')
          .select(
            'id, created_at, blocked_id, blocked:blocked_id(id, username, avatar_url, email)',
          )
          .eq('blocker_id', currentUserId)
          .order('created_at', ascending: false);

      setState(() {
        _blockedUsers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Engelli kullanıcıları yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engellenmiş Kullanıcılar'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBlockedUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _blockedUsers.isEmpty
            ? _buildEmptyState()
            : _buildBlockedList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Engellenmiş kullanıcı yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final blocked = _blockedUsers[index];
        final user = blocked['blocked'] as Map<String, dynamic>?;

        if (user == null) return const SizedBox();

        final username = user['username'] ?? 'Kullanıcı';
        final avatarUrl = user['avatar_url'];
        final createdAt = DateTime.tryParse(blocked['created_at'] ?? '');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.red[100],
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Icon(Icons.block, color: Colors.red[700])
                  : null,
            ),
            title: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              createdAt != null
                  ? 'Engellenme tarihi: ${_formatDate(createdAt)}'
                  : 'Engellendi',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: TextButton.icon(
              onPressed: () => _unblockUser(blocked),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Engeli Kaldır'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unblockUser(Map<String, dynamic> blocked) async {
    final user = blocked['blocked'] as Map<String, dynamic>?;
    final username = user?['username'] ?? 'Kullanıcı';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Engeli Kaldır'),
        content: Text('$username için engeli kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Engeli Kaldır'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final blockedId = blocked['id'];

        // Supabase'den engeli kaldır
        await _supabase.from('blocked_users').delete().eq('id', blockedId);

        // Listeyi yenile
        _loadBlockedUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$username için engel kaldırıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Engel kaldırma hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
