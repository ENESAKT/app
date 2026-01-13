import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/friendship_service.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

/// ProfileScreen - Kullanıcı profil sayfası
///
/// Özellikler:
/// - Profil fotoğrafı, bio, bilgiler
/// - Dinamik butonlar (arkadaşlık durumuna göre)
/// - Mesaj gönder, engelle seçenekleri
class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FriendshipService _friendshipService = FriendshipService();
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, dynamic>? _user;
  String?
  _friendshipStatus; // null, 'pending_sent', 'pending_received', 'friends'
  bool _isLoading = true;
  bool _isActionLoading = false;

  // Renk paleti
  static const Color _primaryColor = Color(0xFF0088CC);
  static const Color _accentColor = Color(0xFF00A8E8);
  static const Color _backgroundColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = await _supabaseService.getUser(widget.userId);

      String? status;
      if (!widget.isCurrentUser) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          status = await _friendshipService.checkFriendshipStatus(
            currentUserId: currentUserId,
            otherUserId: widget.userId,
          );
        }
      }

      setState(() {
        _user = user;
        _friendshipStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Profil yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildErrorState()
          : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    return CustomScrollView(
      slivers: [
        // AppBar with profile header
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: _primaryColor,
          flexibleSpace: FlexibleSpaceBar(background: _buildProfileHeader()),
          actions: [
            if (widget.isCurrentUser)
              IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile)
            else
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'block', child: Text('Engelle')),
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Şikayet Et'),
                  ),
                ],
              ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Action buttons
              if (!widget.isCurrentUser) _buildActionButtons(),

              // Bio section
              _buildBioSection(),

              // Stats
              _buildStatsSection(),

              // Additional info
              _buildInfoSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryColor, _accentColor],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundImage: _user?['avatar_url'] != null
                    ? NetworkImage(_user!['avatar_url'])
                    : null,
                backgroundColor: Colors.white24,
                child: _user?['avatar_url'] == null
                    ? Text(
                        (_user?['username'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // Username
            Text(
              _user?['username'] ?? 'Kullanıcı',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Email or status
            Text(
              _user?['email'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Ana aksiyon butonu
          Expanded(child: _buildPrimaryActionButton()),
          const SizedBox(width: 12),
          // Mesaj butonu (sadece arkadaşlar için)
          if (_friendshipStatus == 'friends')
            Expanded(child: _buildMessageButton()),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton() {
    String text;
    IconData icon;
    Color color;
    VoidCallback? onPressed;

    switch (_friendshipStatus) {
      case 'friends':
        text = 'Arkadaşsınız';
        icon = Icons.check_circle;
        color = Colors.green;
        onPressed = () => _showUnfriendDialog();
        break;
      case 'pending_sent':
        text = 'İstek Gönderildi';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        onPressed = () => _cancelRequest();
        break;
      case 'pending_received':
        text = 'İsteği Kabul Et';
        icon = Icons.person_add;
        color = _primaryColor;
        onPressed = () => _acceptRequest();
        break;
      default:
        text = 'Arkadaş Ekle';
        icon = Icons.person_add;
        color = _primaryColor;
        onPressed = () => _sendRequest();
    }

    return ElevatedButton.icon(
      onPressed: _isActionLoading ? null : onPressed,
      icon: _isActionLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMessageButton() {
    return OutlinedButton.icon(
      onPressed: () => _openChat(),
      icon: const Icon(Icons.message),
      label: const Text('Mesaj'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBioSection() {
    final bio = _user?['bio'];
    if (bio == null || bio.toString().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(bio, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Arkadaş', '24'),
          _buildDivider(),
          _buildStatItem('Mesaj', '156'),
          _buildDivider(),
          _buildStatItem('Katılım', _formatJoinDate()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.alternate_email, _user?['username'] ?? ''),
          const Divider(height: 24),
          _buildInfoRow(Icons.email_outlined, _user?['email'] ?? ''),
          if (_user?['is_online'] == true) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.circle, 'Çevrimiçi', color: Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(fontSize: 15, color: color ?? Colors.black87),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Profil yüklenemedi'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  // Actions
  Future<void> _sendRequest() async {
    setState(() => _isActionLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        await _friendshipService.sendFriendRequest(
          fromUserId: currentUserId,
          toUserId: widget.userId,
        );
        setState(() => _friendshipStatus = 'pending_sent');
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _acceptRequest() async {
    setState(() => _isActionLoading = true);
    // TODO: Accept request logic
    setState(() {
      _friendshipStatus = 'friends';
      _isActionLoading = false;
    });
  }

  Future<void> _cancelRequest() async {
    setState(() => _isActionLoading = true);
    // TODO: Cancel request logic
    setState(() {
      _friendshipStatus = null;
      _isActionLoading = false;
    });
  }

  void _showUnfriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arkadaşlıktan Çık'),
        content: Text(
          '${_user?['username']} ile arkadaşlığı sonlandırmak istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Unfriend logic
            },
            child: const Text('Evet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          friendId: widget.userId,
          friendName: _user?['username'] ?? 'Kullanıcı',
          friendAvatar: _user?['avatar_url'],
        ),
      ),
    );
  }

  void _editProfile() {
    // TODO: Navigate to edit profile
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'block':
        // TODO: Block user
        break;
      case 'report':
        // TODO: Report user
        break;
    }
  }

  String _formatJoinDate() {
    final createdAt = _user?['created_at'];
    if (createdAt == null) return '-';
    try {
      final date = DateTime.parse(createdAt);
      return '${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }
}
