import 'package:flutter/material.dart';

/// Sosyal Profil Ekranı - Instagram tarzı tasarım
///
/// Özellikler:
/// - Profil resmi ve kullanıcı bio
/// - Takipçi, Takip Edilen sayıları
/// - Gradient stilde "Takip Et" ve "Mesaj At" butonları
/// - Grid görünümünde paylaşılan fotoğraflar
class SocialProfileScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? avatarUrl;
  final bool isCurrentUser;

  const SocialProfileScreen({
    super.key,
    this.userId,
    this.userName,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen>
    with SingleTickerProviderStateMixin {
  // Tema renkleri
  static const Color _primaryStart = Color(0xFF667eea);
  static const Color _primaryEnd = Color(0xFF764ba2);
  static const Color _accentColor = Color(0xFFFF6B6B);
  static const Color _backgroundColor = Color(0xFFF8F9FE);

  late TabController _tabController;
  bool _isFollowing = false;

  // Demo veriler
  final int _postsCount = 42;
  final int _followersCount = 1234;
  final int _followingCount = 567;
  final String _displayName = 'Enes Aktaş';
  final String _username = '@enes_aktas';
  final String _bio =
      'Flutter Developer 💙\nCoffee lover ☕\nTech enthusiast 🚀';

  // Demo fotoğraflar için placeholder URL'leri
  final List<String> _photoGrid = List.generate(
    18,
    (index) => 'https://picsum.photos/seed/${index + 1}/300/300',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildProfileInfo()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: _primaryStart,
                indicatorWeight: 3,
                labelColor: _primaryStart,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.bookmark_border)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildPhotoGrid(), _buildSavedGrid()],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _primaryStart,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryStart, _primaryEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
          ),
          onPressed: () => _showOptionsSheet(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Profil fotoğrafı ve istatistikler
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                // Profil resmi
                _buildProfileAvatar(),
                const SizedBox(width: 24),
                // İstatistikler
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Gönderi', _postsCount),
                      _buildStatColumn('Takipçi', _followersCount),
                      _buildStatColumn('Takip', _followingCount),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kullanıcı adı ve bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _bio,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Butonlar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildFollowButton()),
                const SizedBox(width: 12),
                Expanded(child: _buildMessageButton()),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_primaryStart, _primaryEnd, _accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryStart.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: widget.avatarUrl != null
                  ? Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    String formattedCount;
    if (count >= 1000000) {
      formattedCount = '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      formattedCount = '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      formattedCount = count.toString();
    }

    return Column(
      children: [
        Text(
          formattedCount,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          gradient: _isFollowing
              ? null
              : const LinearGradient(
                  colors: [_primaryStart, _primaryEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isFollowing ? Colors.grey[100] : null,
          borderRadius: BorderRadius.circular(12),
          border: _isFollowing ? Border.all(color: Colors.grey[300]!) : null,
          boxShadow: _isFollowing
              ? null
              : [
                  BoxShadow(
                    color: _primaryStart.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isFollowing ? Icons.check : Icons.person_add,
                color: _isFollowing ? Colors.grey[700] : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                style: TextStyle(
                  color: _isFollowing ? Colors.grey[700] : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesajlaşma ekranına yönlendirme 💬'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11998e).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Mesaj At',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _photoGrid.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showPhotoDetail(index),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: Image.network(
              _photoGrid[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: _primaryStart,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kaydedilenler',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz kaydedilen gönderi yok',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_photoGrid[index], fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionItem(Icons.share_outlined, 'Profil Paylaş'),
            _buildOptionItem(Icons.link, 'Bağlantıyı Kopyala'),
            _buildOptionItem(Icons.qr_code, 'QR Kod'),
            _buildOptionItem(Icons.block, 'Engelle', isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => Navigator.pop(context),
    );
  }
}

/// Tab Bar için persistent header delegate
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
