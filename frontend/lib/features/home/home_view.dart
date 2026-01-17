import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HOME VIEW - Ana Sayfa (Hikayeler + Akış)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// - Üst: Yatay kaydırılabilir hikayeler (gradient halka)
/// - Alt: Dikey gönderi akışı (modern kartlar)

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.arkaplanKoyu,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            _buildAppBar(context),

            // Hikayeler Bölümü
            SliverToBoxAdapter(child: _buildStoriesSection(ref)),

            // Ayırıcı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1,
                ),
              ),
            ),

            // Gönderi Akışı
            _buildFeedSection(),
          ],
        ),
      ),
    );
  }

  /// Özel AppBar
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.arkaplanKoyu,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => AppTheme.anaGradient.createShader(bounds),
        child: const Text(
          'Vibe',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
      actions: [
        // Bildirimler
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.turuncuVurgu,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Mesajlar
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Hikayeler Bölümü
  Widget _buildStoriesSection(WidgetRef ref) {
    // Örnek hikaye verileri
    final hikayeler = [
      {'isOwn': true, 'name': 'Sen', 'avatar': null, 'hasStory': false},
      {
        'isOwn': false,
        'name': 'Ayşe',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'hasStory': true,
      },
      {
        'isOwn': false,
        'name': 'Mehmet',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'hasStory': true,
      },
      {
        'isOwn': false,
        'name': 'Zeynep',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'hasStory': true,
      },
      {
        'isOwn': false,
        'name': 'Ali',
        'avatar': 'https://i.pravatar.cc/150?img=7',
        'hasStory': true,
      },
      {
        'isOwn': false,
        'name': 'Fatma',
        'avatar': 'https://i.pravatar.cc/150?img=9',
        'hasStory': false,
      },
      {
        'isOwn': false,
        'name': 'Can',
        'avatar': 'https://i.pravatar.cc/150?img=11',
        'hasStory': true,
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: hikayeler.length,
        itemBuilder: (context, index) {
          final hikaye = hikayeler[index];
          return _buildStoryItem(
            isOwn: hikaye['isOwn'] as bool,
            name: hikaye['name'] as String,
            avatarUrl: hikaye['avatar'] as String?,
            hasStory: hikaye['hasStory'] as bool,
          );
        },
      ),
    );
  }

  /// Tek hikaye öğesi
  Widget _buildStoryItem({
    required bool isOwn,
    required String name,
    String? avatarUrl,
    required bool hasStory,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar container
          Stack(
            children: [
              // Gradient halka (hikaye varsa)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStory ? AppTheme.anaGradient : null,
                  border: !hasStory
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.arkaplanKoyu,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppTheme.kartArkaplani),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.kartArkaplani,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.kartArkaplani,
                            child: Icon(
                              isOwn ? Icons.add : Icons.person,
                              color: Colors.white54,
                              size: 28,
                            ),
                          ),
                  ),
                ),
              ),

              // Kendi hikayen için artı butonu
              if (isOwn)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppTheme.anaGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.arkaplanKoyu,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // İsim
          SizedBox(
            width: 72,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gönderi Akışı
  Widget _buildFeedSection() {
    // Örnek gönderi verileri
    final gonderiler = [
      {
        'user': 'Ayşe Yılmaz',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'time': '2 saat önce',
        'content': 'Bugün harika bir gün geçirdim! ☀️',
        'image': 'https://picsum.photos/600/400?random=1',
        'likes': 128,
        'comments': 24,
      },
      {
        'user': 'Mehmet Kaya',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'time': '5 saat önce',
        'content': 'Yeni projem üzerinde çalışıyorum 💻',
        'image': 'https://picsum.photos/600/400?random=2',
        'likes': 89,
        'comments': 12,
      },
      {
        'user': 'Zeynep Demir',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'time': '1 gün önce',
        'content': 'Kahve zamanı ☕',
        'image': 'https://picsum.photos/600/400?random=3',
        'likes': 256,
        'comments': 45,
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final gonderi = gonderiler[index];
        return _buildPostCard(
          userName: gonderi['user'] as String,
          avatarUrl: gonderi['avatar'] as String,
          time: gonderi['time'] as String,
          content: gonderi['content'] as String,
          imageUrl: gonderi['image'] as String,
          likes: gonderi['likes'] as int,
          comments: gonderi['comments'] as int,
        );
      }, childCount: gonderiler.length),
    );
  }

  /// Gönderi kartı
  Widget _buildPostCard({
    required String userName,
    required String avatarUrl,
    required String time,
    required String content,
    required String imageUrl,
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.kartArkaplani,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık (Avatar, isim, zaman)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.anaGradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // İsim ve zaman
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menü
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // İçerik metni
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Görsel
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 280,
                color: AppTheme.yuzeyRengi,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.morVurgu),
                ),
              ),
            ),
          ),

          // Aksiyonlar (Beğen, Yorum, Paylaş)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Beğen
                _buildActionButton(
                  icon: Icons.favorite_outline,
                  label: _formatCount(likes),
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                // Yorum
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(comments),
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                // Paylaş
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Paylaş',
                  onTap: () {},
                ),
                const Spacer(),
                // Kaydet
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.bookmark_outline,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aksiyon butonu (beğen, yorum vb.)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Sayı formatlama (1000 -> 1K)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
