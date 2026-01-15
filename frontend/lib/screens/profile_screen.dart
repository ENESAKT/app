import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fake_user_model.dart';
import '../services/friendship_service.dart';
import '../services/supabase_service.dart';
import '../services/post_service.dart';
import 'chat_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MODERN PROFILE SCREEN
/// Arkadaşlık uygulaması tarzında modern profil sayfası
/// ═══════════════════════════════════════════════════════════════════════════

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
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _user;
  String? _friendshipStatus;
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isEditingBio = false;
  final TextEditingController _bioController = TextEditingController();

  // Stats
  int _friendCount = 0;
  int _postCount = 0;

  // 🎨 Modern Renk Paleti
  static const Color _primaryStart = Color(0xFF667eea);
  static const Color _primaryEnd = Color(0xFF764ba2);
  static const Color _accentColor = Color(0xFF00D9FF);
  static const Color _cardBg = Colors.white;
  static const Color _background = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? user;

      // Fake user kontrolü
      if (isFakeUserId(widget.userId)) {
        // Fake user - tutarlı veri üret
        final fakeUser = generateFakeUserById(widget.userId);
        user = fakeUser.toMap();

        // Fake stats (hash-based tutarlı)
        final seed = widget.userId.hashCode.abs();
        _friendCount = 5 + (seed % 45);
        _postCount = 1 + (seed % 30);
      } else {
        // Gerçek user - Supabase'den çek
        user = await _supabaseService.getUser(widget.userId);

        // Gerçek stats yükle
        await _loadRealStats();
      }

      String? status;
      if (!widget.isCurrentUser && !isFakeUserId(widget.userId)) {
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
        _bioController.text = user?['bio'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Profil yükleme hatası: $e');
    }
  }

  Future<void> _loadRealStats() async {
    try {
      // Arkadaş sayısı
      final friends = await _friendshipService.getFriends(
        userId: widget.userId,
      );
      _friendCount = friends.length;

      // Gönderi sayısı
      final postService = PostService();
      final posts = await postService.getUserPosts(
        userId: widget.userId,
        limit: 100,
      );
      _postCount = posts.length;
    } catch (e) {
      print('❌ Stats yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildErrorState()
          : _buildModernProfile(),
      floatingActionButton: widget.isCurrentUser ? _buildPhotoFab() : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODERN PROFILE LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModernProfile() {
    return CustomScrollView(
      slivers: [
        // 🎨 Gradient Header with Profile Photo
        SliverToBoxAdapter(child: _buildGradientHeader()),

        // 📋 Content Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Action Buttons (for others)
                if (!widget.isCurrentUser) _buildActionButtons(),

                // 📝 Info Card (Name, Age, City)
                _buildInfoCard(),

                const SizedBox(height: 16),

                // 💭 About Me Card
                _buildAboutMeCard(),

                const SizedBox(height: 16),

                // 🏷 Interests Card
                _buildInterestsCard(),

                const SizedBox(height: 16),

                // 📊 Stats Card
                _buildStatsCard(),

                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT HEADER WITH LARGE PROFILE PHOTO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGradientHeader() {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryStart, _primaryEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.isCurrentUser ? 'Profilim' : 'Profil',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  widget.isCurrentUser
                      ? IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: _handleMenuAction,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'block',
                              child: Text('Engelle'),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Şikayet Et'),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🖼 Large Profile Photo Card
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: _user?['avatar_url'] != null
                    ? Image.network(
                        _user!['avatar_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),

            const SizedBox(height: 16),

            // Username
            Text(
              _user?['username'] ?? 'Kullanıcı',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            // Online status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _user?['is_online'] == true
                        ? Colors.greenAccent
                        : Colors.white54,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _user?['is_online'] == true ? 'Çevrimiçi' : 'Çevrimdışı',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(
          (_user?['username'] ?? 'U')[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO CARD (Name, Age, City)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInfoCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline,
            'İsim',
            _user?['username'] ?? '-',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.cake_outlined,
            'Yaş',
            _user?['age']?.toString() ?? '-',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Şehir',
            _user?['city'] ?? '-',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.email_outlined,
            'E-posta',
            _user?['email'] ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryStart, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABOUT ME CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAboutMeCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: _accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Hakkımda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (widget.isCurrentUser)
                IconButton(
                  icon: Icon(
                    _isEditingBio ? Icons.check : Icons.edit,
                    color: _primaryStart,
                  ),
                  onPressed: _toggleBioEdit,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditingBio)
            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Kendinizden bahsedin...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            Text(
              _user?['bio']?.isNotEmpty == true
                  ? _user!['bio']
                  : 'Henüz bir şey yazmadı...',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  void _toggleBioEdit() async {
    if (_isEditingBio) {
      // Kaydet
      await _supabaseService.updateProfile(bio: _bioController.text);
      await _loadProfile();
    }
    setState(() => _isEditingBio = !_isEditingBio);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERESTS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInterestsCard() {
    final interests = _supabaseService.parseInterests(_user?['interests']);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.interests,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'İlgi Alanları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (interests.isEmpty)
            Text(
              'Henüz ilgi alanı eklenmedi',
              style: TextStyle(color: Colors.grey[500]),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: interests.map((interest) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(interest),
                      backgroundColor: _primaryStart.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: _primaryStart,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsCard() {
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('👥', 'Arkadaş', _friendCount.toString()),
          _buildStatDivider(),
          _buildStatItem('📝', 'Gönderi', _postCount.toString()),
          _buildStatDivider(),
          _buildStatItem('📅', 'Katılım', _formatJoinDate()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 50, width: 1, color: Colors.grey[200]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: _buildPrimaryActionButton()),
          const SizedBox(width: 12),
          if (_friendshipStatus == 'friends')
            Expanded(child: _buildMessageButton()),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton() {
    String text;
    IconData icon;
    List<Color> colors;
    VoidCallback? onPressed;

    switch (_friendshipStatus) {
      case 'friends':
        text = 'Arkadaşsınız';
        icon = Icons.check_circle;
        colors = [Colors.green, Colors.green.shade700];
        onPressed = () => _showUnfriendDialog();
        break;
      case 'pending_sent':
        text = 'İstek Gönderildi';
        icon = Icons.hourglass_empty;
        colors = [Colors.orange, Colors.deepOrange];
        onPressed = () => _cancelRequest();
        break;
      case 'pending_received':
        text = 'İsteği Kabul Et';
        icon = Icons.person_add;
        colors = [_primaryStart, _primaryEnd];
        onPressed = () => _acceptRequest();
        break;
      default:
        text = 'Arkadaş Ekle';
        icon = Icons.person_add;
        colors = [_primaryStart, _primaryEnd];
        onPressed = () => _sendRequest();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isActionLoading ? null : onPressed,
        icon: _isActionLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return OutlinedButton.icon(
      onPressed: () => _openChat(),
      icon: const Icon(Icons.message),
      label: const Text('Mesaj'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryStart,
        side: const BorderSide(color: _primaryStart, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO FAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPhotoFab() {
    return FloatingActionButton(
      onPressed: _pickAndUploadPhoto,
      backgroundColor: _primaryStart,
      child: const Icon(Icons.camera_alt, color: Colors.white),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isActionLoading = true);

      final url = await _supabaseService.uploadProfilePhoto(image.path);

      if (url != null) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profil fotoğrafı güncellendi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Fotoğraf seçme hatası: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Profil yüklenemedi', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

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
    setState(() {
      _friendshipStatus = 'friends';
      _isActionLoading = false;
    });
  }

  Future<void> _cancelRequest() async {
    setState(() => _isActionLoading = true);
    setState(() {
      _friendshipStatus = null;
      _isActionLoading = false;
    });
  }

  void _showUnfriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
