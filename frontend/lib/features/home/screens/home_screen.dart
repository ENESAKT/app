import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/story_item.dart';
import '../widgets/post_card.dart';

/// FeedHomeScreen - Premium Dark Theme Ana Sayfa
///
/// Features:
/// - Dark theme (#0D0D0D) arka plan
/// - Gradient hikayeler (izlenmemiş = mor-turuncu halka)
/// - Modern post kartları (#1E1E1E)
/// - Glassmorphism AppBar
/// - Pull-to-refresh
class FeedHomeScreen extends StatefulWidget {
  const FeedHomeScreen({super.key});

  @override
  State<FeedHomeScreen> createState() => _FeedHomeScreenState();
}

class _FeedHomeScreenState extends State<FeedHomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  // Animasyon
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Current user info
  String? _currentUserAvatarUrl;
  String _currentUsername = '';

  // Fake data for demo
  List<StoryData> _stories = [];
  List<PostData> _posts = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _loadUserData();
    _loadFeedData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      setState(() {
        _currentUsername =
            metadata?['full_name'] ??
            metadata?['name'] ??
            user.email?.split('@').first ??
            'Kullanıcı';
        _currentUserAvatarUrl = metadata?['avatar_url'] ?? metadata?['picture'];
      });
    }
  }

  Future<void> _loadFeedData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    _stories = _generateFakeStories();
    _posts = _generateFakePosts();

    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  List<StoryData> _generateFakeStories() {
    final names = [
      'Elif',
      'Ahmet',
      'Zeynep',
      'Mehmet',
      'Ayşe',
      'Can',
      'Deniz',
      'Ece',
      'Burak',
      'Selin',
    ];

    return List.generate(10, (index) {
      final name = names[index % names.length];
      return StoryData(
        id: 'story_$index',
        userId: 'user_$index',
        username: name,
        avatarUrl: 'https://i.pravatar.cc/150?img=${index + 10}',
        hasUnviewed: index < 6,
      );
    });
  }

  List<PostData> _generateFakePosts() {
    final users = [
      {'name': 'Elif Yılmaz', 'location': 'İstanbul, Türkiye'},
      {'name': 'Ahmet Kaya', 'location': 'Ankara, Türkiye'},
      {'name': 'Zeynep Demir', 'location': 'İzmir, Türkiye'},
      {'name': 'Mert Özkan', 'location': 'Antalya, Türkiye'},
      {'name': 'Selin Arslan', 'location': 'Bursa, Türkiye'},
    ];

    final captions = [
      'Harika bir gün geçirdim! ☀️ #mutluluk',
      'Bu manzaraya bayıldım 🏔️',
      'Arkadaşlarla güzel anlar 💕',
      'Yeni maceralar için hazırım! 🚀',
      'Güneşli günlerin tadını çıkarıyorum 🌊',
    ];

    return List.generate(10, (index) {
      final user = users[index % users.length];
      final caption = captions[index % captions.length];

      return PostData(
        id: 'post_$index',
        userId: 'user_$index',
        username: user['name']!,
        userAvatarUrl: 'https://i.pravatar.cc/150?img=${index + 20}',
        imageUrl: 'https://picsum.photos/seed/post$index/800/800',
        caption: caption,
        location: user['location'],
        likeCount: 100 + (index * 47) % 500,
        commentCount: 10 + (index * 13) % 100,
        isLiked: index % 3 == 0,
        isSaved: index % 5 == 0,
        createdAt: DateTime.now().subtract(Duration(hours: index * 3 + 1)),
      );
    });
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadFeedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF8B5CF6),
                backgroundColor: const Color(0xFF1E1E1E),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Stories Bar
                      SliverToBoxAdapter(child: _buildStoriesSection()),

                      // Divider
                      SliverToBoxAdapter(
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),

                      // Posts Feed
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = _posts[index];
                          return _buildDarkPostCard(post);
                        }, childCount: _posts.length),
                      ),

                      // Bottom padding for navigation bar
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Glassmorphism SliverAppBar - Dark Theme
  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      backgroundColor: innerBoxIsScrolled
          ? const Color(0xFF0D0D0D).withOpacity(0.95)
          : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
        ).createShader(bounds),
        child: const Text(
          'Vibe',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
      ),
      actions: [
        // Bildirimler
        _buildAppBarIcon(
          icon: Icons.favorite_border_rounded,
          onTap: _onNotificationsTap,
          hasBadge: true,
        ),
        // Mesajlar
        _buildAppBarIcon(
          icon: Icons.send_outlined,
          onTap: _onMessagesTap,
          hasBadge: false,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            if (hasBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0D0D0D),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF8B5CF6),
        strokeWidth: 2,
      ),
    );
  }

  /// Hikayeler Bölümü - Dark Theme
  Widget _buildStoriesSection() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryItem();
          }
          final story = _stories[index - 1];
          return _buildStoryItem(story);
        },
      ),
    );
  }

  /// Hikaye Ekle Butonu - Dark Theme
  Widget _buildAddStoryItem() {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E1E1E),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF2A2A2A),
                  backgroundImage: _currentUserAvatarUrl != null
                      ? NetworkImage(_currentUserAvatarUrl!)
                      : null,
                  child: _currentUserAvatarUrl == null
                      ? Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.4),
                          size: 28,
                        )
                      : null,
                ),
                // Add icon
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0D0D0D),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hikaye Ekle',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Story Item - Dark Theme + Gradient Ring
  Widget _buildStoryItem(StoryData story) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _onStoryTap(story),
        child: Column(
          children: [
            // Gradient ring for unseen stories
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.hasUnviewed
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFF97316),
                          Color(0xFFEC4899),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D0D),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF2A2A2A),
                  backgroundImage: story.avatarUrl != null
                      ? NetworkImage(story.avatarUrl!)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.username,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Dark Post Card
  Widget _buildDarkPostCard(PostData post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar with gradient ring
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2A2A2A),
                    backgroundImage: post.userAvatarUrl != null
                        ? NetworkImage(post.userAvatarUrl!)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Username & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (post.location != null)
                        Text(
                          post.location!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // More button
                IconButton(
                  onPressed: () => _showPostMenu(post),
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Post Image
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFF1E1E1E),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF8B5CF6),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Like
                _buildActionButton(
                  icon: post.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border_rounded,
                  color: post.isLiked ? Colors.red : Colors.white,
                  onTap: () => _onLikePost(post.id),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => _onCommentPost(post.id),
                ),
                _buildActionButton(
                  icon: Icons.send_outlined,
                  onTap: () => _onSharePost(post.id),
                ),
                const Spacer(),
                // Save
                _buildActionButton(
                  icon: post.isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  onTap: () => _onSavePost(post.id),
                ),
              ],
            ),
          ),

          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${post.likeCount} beğenme',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: post.username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(text: post.caption),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              _formatTimeAgo(post.createdAt),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color ?? Colors.white, size: 26),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes} dakika önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    return '${difference.inDays} gün önce';
  }

  // Action handlers
  void _onStoryTap(StoryData story) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${story.username} hikayesi açılıyor...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1E1E),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onLikePost(String postId) {
    HapticFeedback.lightImpact();
    print('Like post: $postId');
  }

  void _onCommentPost(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yorumlar yakında!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }

  void _onSharePost(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşma yakında!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }

  void _onSavePost(String postId) {
    HapticFeedback.selectionClick();
    print('Save post: $postId');
  }

  void _showPostMenu(PostData post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMenuTile(Icons.report_outlined, 'Şikayet Et', Colors.red),
            _buildMenuTile(Icons.block_outlined, 'Engelle', null),
            _buildMenuTile(Icons.hide_source_outlined, 'Gizle', null),
            _buildMenuTile(Icons.link_outlined, 'Bağlantıyı Kopyala', null),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, Color? color) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white.withOpacity(0.8)),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      onTap: () => Navigator.pop(context),
    );
  }

  void _onNotificationsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirimler yakında!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }

  void _onMessagesTap() {
    Navigator.pushNamed(context, '/conversations');
  }
}
