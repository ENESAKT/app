import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/reel_item.dart';

/// ReelsScreen - TikTok tarzı tam ekran Reels player
///
/// Features:
/// - PageView ile dikey kaydırma (sayfa sayfa)
/// - Her sayfada ReelItem widget
/// - Üstte Reels/Takip edilenler sekmeleri
/// - Tam ekran immersive deneyim
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;

  int _currentIndex = 0;
  bool _showForYou = true;
  List<ReelData> _reels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadReels() {
    // Generate fake reels data
    _reels = _generateFakeReels();
  }

  List<ReelData> _generateFakeReels() {
    final users = [
      {'name': 'elif_travel', 'fullName': 'Elif Yılmaz', 'verified': true},
      {'name': 'ahmet_food', 'fullName': 'Ahmet Kaya', 'verified': false},
      {'name': 'zeynep_life', 'fullName': 'Zeynep Demir', 'verified': true},
      {'name': 'can_tech', 'fullName': 'Can Özkan', 'verified': false},
      {'name': 'deniz_art', 'fullName': 'Deniz Arslan', 'verified': true},
      {'name': 'ece_dance', 'fullName': 'Ece Yıldız', 'verified': false},
      {'name': 'burak_music', 'fullName': 'Burak Koç', 'verified': true},
    ];

    final descriptions = [
      'Bu manzaraya bayıldım! 🏔️ #travel #explore',
      'Evde kolayca yapabileceğiniz tarif 🍝 #yemek #tarif',
      'Günlük rutinimden bir kesit ✨ #lifestyle #vlog',
      'Bu özelliği biliyor muydunuz? 📱 #tech #tips',
      'Son çalışmam nasıl olmuş? 🎨 #art #creative',
      'Yeni dans challenge! 💃 #dance #trend',
      'Yeni şarkımdan bir bölüm 🎵 #music #cover',
    ];

    final sounds = [
      'Yeni Trend Müzik - DJ Mix',
      'Orijinal Ses',
      'Viral Sound 2026',
      'Popular Beat',
      'Trending Audio',
      'Dance Mix',
      'Acoustic Cover',
    ];

    return List.generate(15, (index) {
      final user = users[index % users.length];
      final description = descriptions[index % descriptions.length];
      final sound = sounds[index % sounds.length];

      return ReelData(
        id: 'reel_$index',
        userId: 'user_$index',
        username: user['name'] as String,
        userAvatarUrl: 'https://i.pravatar.cc/150?img=${index + 30}',
        thumbnailUrl: 'https://picsum.photos/seed/reel$index/1080/1920',
        description: description,
        soundName: sound,
        soundImageUrl: 'https://i.pravatar.cc/150?img=${index + 40}',
        likeCount: (index + 1) * 1234 + (index * 567) % 10000,
        commentCount: (index + 1) * 89 + (index * 23) % 500,
        isLiked: index % 4 == 0,
        isFollowing: index % 3 == 0,
        isVerified: user['verified'] == true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar for immersive experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          final reel = _reels[index];
          return ReelItem(
            reel: reel,
            onLike: () => _onLikeReel(reel.id),
            onComment: () => _onCommentReel(reel.id),
            onShare: () => _onShareReel(reel.id),
            onProfileTap: () => _onProfileTap(reel.userId),
            onFollow: () => _onFollowUser(reel.userId),
            onSoundTap: () => _onSoundTap(reel.soundName),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Takip Edilenler
          GestureDetector(
            onTap: () {
              setState(() => _showForYou = false);
              _tabController.animateTo(0);
            },
            child: Text(
              'Takip Edilenler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: !_showForYou ? FontWeight.bold : FontWeight.normal,
                color: !_showForYou
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Senin İçin
          GestureDetector(
            onTap: () {
              setState(() => _showForYou = true);
              _tabController.animateTo(1);
            },
            child: Text(
              'Senin İçin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: _showForYou ? FontWeight.bold : FontWeight.normal,
                color: _showForYou
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _onCameraTap,
          icon: const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
        IconButton(
          onPressed: _onSearchTap,
          icon: const Icon(
            Icons.search,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
      ],
    );
  }

  // Action handlers
  void _onLikeReel(String reelId) {
    print('Like reel: $reelId');
  }

  void _onCommentReel(String reelId) {
    _showCommentsSheet(reelId);
  }

  void _showCommentsSheet(String reelId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Yorumlar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // Divider
            Divider(height: 1, color: Colors.grey.shade200),
            // Comments list placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz yorum yok',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İlk yorumu sen yap!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Comment input
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Yorum ekle...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onShareReel(String reelId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Paylaş',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildShareOption(Icons.message, 'Mesaj'),
                  _buildShareOption(Icons.content_copy, 'Kopyala'),
                  _buildShareOption(Icons.share, 'Diğer'),
                  _buildShareOption(Icons.bookmark_border, 'Kaydet'),
                  _buildShareOption(Icons.more_horiz, 'Daha Fazla'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _onProfileTap(String userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  void _onFollowUser(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Takip edildi!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onSoundTap(String? soundName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎵 $soundName'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onCameraTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reels oluşturma yakında!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchTap() {
    Navigator.pushNamed(context, '/search');
  }
}
