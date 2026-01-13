import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';

/// PostWidget - Instagram tarzı post kartı
///
/// Core Features:
/// - Header: Avatar, username, more menu
/// - Media: Image/Video/Carousel desteği
/// - Actions: Like (animated), Comment, Share, Save
/// - Footer: Like count, caption, comment count, timestamp
///
/// Optimistic UI: Like anında görsel güncelleme
class PostWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;

  const PostWidget({
    super.key,
    required this.post,
    this.onDoubleTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onProfileTap,
    this.onMoreTap,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
    with SingleTickerProviderStateMixin {
  // Animasyon için
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnimation;
  bool _showHeartOverlay = false;

  // Carousel için
  int _currentMediaIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _likeAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      widget.onLike?.call();
    }
    _showHeartAnimation();
    widget.onDoubleTap?.call();
  }

  void _showHeartAnimation() {
    HapticFeedback.lightImpact();
    setState(() => _showHeartOverlay = true);
    _likeAnimController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _likeAnimController.reverse().then((_) {
          if (mounted) setState(() => _showHeartOverlay = false);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildMedia(),
          _buildActions(),
          _buildFooter(),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// Post Header: Avatar, Username, More Menu
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: widget.onProfileTap,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: widget.post.authorAvatarUrl != null
                  ? NetworkImage(widget.post.authorAvatarUrl!)
                  : null,
              backgroundColor: Colors.grey.shade200,
              child: widget.post.authorAvatarUrl == null
                  ? Text(
                      (widget.post.authorUsername ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Username & Location
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.post.authorUsername ?? 'kullanıcı',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.post.authorIsVerified == true) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  if (widget.post.location != null)
                    Text(
                      widget.post.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // More Menu
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: widget.onMoreTap ?? () => _showMoreMenu(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Media: Image/Video/Carousel
  Widget _buildMedia() {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Media Content
          if (widget.post.isCarousel) _buildCarousel() else _buildSingleMedia(),
          // Heart Overlay Animation
          if (_showHeartOverlay)
            ScaleTransition(
              scale: _likeScaleAnimation,
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 100,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleMedia() {
    final mediaUrl = widget.post.primaryMediaUrl;
    if (mediaUrl == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Image.network(
        mediaUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.post.mediaUrls.length,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.post.mediaUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              );
            },
          ),
        ),
        // Page Indicator
        if (widget.post.mediaUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.post.mediaUrls.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentMediaIndex
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Actions Row: Like, Comment, Share, Save
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Like Button
          _ActionButton(
            icon: widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: widget.post.isLiked ? Colors.red : Colors.black,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onLike?.call();
            },
          ),
          // Comment Button
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            onTap: widget.onComment,
          ),
          // Share Button
          _ActionButton(icon: Icons.send_outlined, onTap: widget.onShare),
          const Spacer(),
          // Save Button
          _ActionButton(
            icon: widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onSave?.call();
            },
          ),
        ],
      ),
    );
  }

  /// Footer: Like count, Caption, Comments, Timestamp
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like Count
          if (widget.post.likeCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${widget.post.likeCount} beğenme',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '${widget.post.authorUsername ?? "kullanıcı"} ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: widget.post.caption),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // View Comments
          if (widget.post.commentCount > 0)
            GestureDetector(
              onTap: widget.onComment,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${widget.post.commentCount} yorumun tümünü gör',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ),
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.post.timeAgo,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.red),
              title: const Text(
                'Şikayet Et',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('Takibi Bırak'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Bağlantıyı Kopyala'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bağlantı kopyalandı')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Reusable Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.color = Colors.black,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 26),
      color: color,
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}
