import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fake_user_model.dart';

/// HomeScreen - Modern Sosyal Medya Ana Ekranı
///
/// Features:
/// - Gradient AppBar ile kullanıcı profil kartı
/// - Renkli storyler çubuğu
/// - Sahte kullanıcılar listesi (GridView)
/// - Pull-to-refresh
/// - Modern ve canlı tasarım
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Kullanıcı bilgileri (Supabase Auth'dan)
  User? _currentUser;
  String _displayName = '';
  String? _avatarUrl;

  // Sahte kullanıcılar
  List<FakeUser> _fakeUsers = [];
  List<FakeStory> _fakeStories = [];

  bool _isLoading = true;

  // Animasyon controller
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Animasyon
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _loadUserData();
    _loadFakeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Supabase Auth'dan kullanıcı verilerini yükle
  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      setState(() {
        _currentUser = user;

        // Google OAuth'dan gelen veriler
        final metadata = user.userMetadata;
        _displayName =
            metadata?['full_name'] ??
            metadata?['name'] ??
            user.email?.split('@').first ??
            'Kullanıcı';
        _avatarUrl = metadata?['avatar_url'] ?? metadata?['picture'];

        print('👤 Kullanıcı yüklendi: $_displayName');
        print('📸 Avatar URL: $_avatarUrl');
      });
    }
  }

  /// Sahte verileri yükle
  void _loadFakeData() async {
    // Biraz gecikme ekle (gerçek API çağrısı simülasyonu)
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _fakeUsers = generateFakeUsers();
      _fakeStories = generateFakeStories();
      _isLoading = false;
    });

    _fadeController.forward();
  }

  /// Yenile
  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    _loadUserData();

    setState(() {
      _fakeUsers = generateFakeUsers();
      _fakeStories = generateFakeStories();
      _isLoading = false;
    });

    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.secondary.withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: colorScheme.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 🎨 Gradient AppBar
                _buildSliverAppBar(colorScheme),

                // 📸 Hikayeler Çubuğu
                SliverToBoxAdapter(child: _buildStoriesSection()),

                // 📊 Keşfet Başlığı
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Keşfet', Icons.explore),
                ),

                // 👥 Kullanıcılar Grid
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _buildUsersGrid(),
                  ),

                // Alt boşluk
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),

      // 🎯 Floating Action Button
      floatingActionButton: _buildFAB(colorScheme),
    );
  }

  /// Gradient SliverAppBar - Kullanıcı Profil Kartı
  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 220, // Overflow düzeltmesi
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
                colorScheme.primary,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst satır - Logo ve Bildirimler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Arkadaşlık',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildIconButton(Icons.apps_rounded, () {
                            Navigator.pushNamed(context, '/apps-hub');
                          }),
                          const SizedBox(width: 8),
                          _buildIconButton(Icons.search, () {
                            Navigator.pushNamed(context, '/search');
                          }),
                          const SizedBox(width: 8),
                          _buildIconButton(Icons.notifications_outlined, () {
                            // TODO: Bildirimler
                          }),
                          const SizedBox(width: 8),
                          _buildIconButton(Icons.settings_outlined, () {
                            Navigator.pushNamed(context, '/settings');
                          }),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Kullanıcı Profil Kartı
                  _buildUserProfileCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// AppBar Icon Button
  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  /// Kullanıcı Profil Kartı
  Widget _buildUserProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: _avatarUrl != null
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null
                  ? Text(
                      _displayName.isNotEmpty
                          ? _displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 16),

          // Kullanıcı Bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Çevrimiçi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profil Düzenle Butonu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Profil',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hikayeler Bölümü
  Widget _buildStoriesSection() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _fakeStories.length + 1, // +1 for "Add Story"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Hikaye Ekle
            return _buildAddStoryItem();
          }

          final story = _fakeStories[index - 1];
          return _buildStoryItem(story);
        },
      ),
    );
  }

  /// Hikaye Ekle Butonu
  Widget _buildAddStoryItem() {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? Icon(
                            Icons.person,
                            color: Colors.grey.shade400,
                            size: 28,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hikaye Ekle',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Story Item
  Widget _buildStoryItem(FakeStory story) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: story.hasUnseenStory
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFF58529),
                        Color(0xFFDD2A7B),
                        Color(0xFF8134AF),
                        Color(0xFF515BD4),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                    ),
              shape: BoxShape.circle,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(story.avatarUrl),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            story.username,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Bölüm Başlığı
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            child: const Text(
              'Tümünü Gör',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Kullanıcılar Grid
  Widget _buildUsersGrid() {
    return SliverFadeTransition(
      opacity: _fadeAnimation,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72, // Overflow için düzeltme
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildUserCard(_fakeUsers[index], index),
          childCount: _fakeUsers.length,
        ),
      ),
    );
  }

  /// Kullanıcı Kartı
  Widget _buildUserCard(FakeUser user, int index) {
    // Renkli gradient listesi
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],
      [const Color(0xFF5EE7DF), const Color(0xFFB490CA)],
      [const Color(0xFFD299C2), const Color(0xFFFEF9D7)],
      [const Color(0xFF89F7FE), const Color(0xFF66A6FF)],
    ];

    final colors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Profil sayfasına git
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${user.name} profiline gidiliyor...'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Üst Gradient Banner
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              // Avatar (overlap)
              Transform.translate(
                offset: const Offset(0, -30),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: colors[0].withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(user.avatarUrl),
                      ),
                    ),
                    // Online indicator
                    if (user.isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // İsim ve Bio
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (user.mutualFriends > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${user.mutualFriends} ortak arkadaş',
                            style: TextStyle(
                              color: colors[0],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Arkadaş Ekle Butonu
              Transform.translate(
                offset: const Offset(0, -12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${user.name} için istek gönderildi! 🎉',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: colors[0],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors[0],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Arkadaş Ekle',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Floating Action Button
  Widget _buildFAB(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Yeni post / hikaye ekle
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildActionSheet(),
        );
      },
      backgroundColor: const Color(0xFF667eea),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Paylaş',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Action Sheet
  Widget _buildActionSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ne Paylaşmak İstersin?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionItem(
                icon: Icons.photo_library,
                label: 'Gönderi',
                color: const Color(0xFF667eea),
                onTap: () => Navigator.pop(context),
              ),
              _buildActionItem(
                icon: Icons.camera_alt,
                label: 'Hikaye',
                color: const Color(0xFFF58529),
                onTap: () => Navigator.pop(context),
              ),
              _buildActionItem(
                icon: Icons.videocam,
                label: 'Video',
                color: const Color(0xFFDD2A7B),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Action Item
  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
