import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

/// PostCard - Instagram tarzı gönderi kartı
///
/// Features:
/// - Avatar, kullanıcı adı, konum başlığı
/// - Tam genişlik resim
/// - Beğen, yorum, paylaş, kaydet butonları
/// - Beğeni sayısı, açıklama, yorum sayısı
/// - Double-tap ile beğenme + kalp animasyonu
class PostCard extends StatefulWidget {
  final PostData post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onProfileTap,
    this.onMoreTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  bool _showHeart = false;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartController);

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartController);

    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!_isLiked) {
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
      widget.onLike?.call();
    }
    _showHeartAnimation();
  }

  void _showHeartAnimation() {
    setState(() => _showHeart = true);
    _heartController.reset();
    _heartController.forward();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildMediaSection(),
          _buildActionsRow(),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Header: Avatar, username, location, more button
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: ClipOval(
                child: widget.post.userAvatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.post.userAvatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.person, color: Colors.grey.shade400),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.person, color: Colors.grey.shade400),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Username & Location
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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

          // More button
          IconButton(
            onPressed: widget.onMoreTap,
            icon: const Icon(Icons.more_horiz),
            iconSize: 24,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  /// Media section with double-tap like
  Widget _buildMediaSection() {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),

          // Heart Animation
          if (_showHeart)
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Opacity(
                  opacity: _heartOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _heartScaleAnimation.value,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                      shadows: [Shadow(blurRadius: 20, color: Colors.black26)],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Actions row: Like, Comment, Share, Save
  Widget _buildActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Like button
          _ActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.black87,
            onTap: _toggleLike,
          ),
          // Comment button
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            onTap: widget.onComment,
          ),
          // Share button
          _ActionButton(icon: Icons.send_outlined, onTap: widget.onShare),
          const Spacer(),
          // Save button
          _ActionButton(
            icon: widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            onTap: widget.onSave,
          ),
        ],
      ),
    );
  }

  /// Footer: Likes, Caption, Comments, Timestamp
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like count
          Text(
            '$_likeCount beğenme',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),

          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: widget.post.username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(text: widget.post.caption),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),

          // View comments
          if (widget.post.commentCount > 0)
            GestureDetector(
              onTap: widget.onComment,
              child: Text(
                '${widget.post.commentCount} yorumun tümünü gör',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          const SizedBox(height: 4),

          // Timestamp
          Text(
            _formatTimestamp(widget.post.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    return timeago.format(time, locale: 'tr');
  }
}

/// Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.color = Colors.black87,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: color,
      iconSize: 26,
      splashRadius: 24,
    );
  }
}

/// Post data model
class PostData {
  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String imageUrl;
  final String? caption;
  final String? location;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;

  const PostData({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.imageUrl,
    this.caption,
    this.location,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
  });
}
