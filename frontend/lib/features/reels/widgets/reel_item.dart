import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ReelItem - TikTok tarzı tek bir reel kartı
///
/// Features:
/// - Tam ekran video placeholder (siyah arkaplan)
/// - Sağ tarafta dikey action butonlar
/// - Alt tarafta kullanıcı bilgisi
/// - Animasyonlu beğeni
class ReelItem extends StatefulWidget {
  final ReelData reel;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFollow;
  final VoidCallback? onSoundTap;

  const ReelItem({
    super.key,
    required this.reel,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onProfileTap,
    this.onFollow,
    this.onSoundTap,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = false;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reel.isLiked;
    _likeCount = widget.reel.likeCount;

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
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
    HapticFeedback.mediumImpact();
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
    HapticFeedback.selectionClick();
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background (placeholder - siyah arkaplan)
          _buildVideoBackground(),

          // Heart Animation
          if (_showHeart) _buildHeartAnimation(),

          // Right Side Actions
          _buildRightActions(),

          // Bottom Info
          _buildBottomInfo(),

          // Top Gradient
          _buildTopGradient(),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Container(
      color: Colors.black,
      child: widget.reel.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.reel.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white24,
                    size: 80,
                  ),
                ),
              ),
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: Colors.white24,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Video Player\n(Yakında)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeartAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: _heartController,
        builder: (context, child) {
          return Transform.scale(
            scale: _heartAnimation.value,
            child: Icon(
              Icons.favorite,
              color: Colors.white.withOpacity(
                _heartAnimation.value > 0 ? 1.0 : 0.0,
              ),
              size: 120,
              shadows: const [Shadow(blurRadius: 30, color: Colors.black38)],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 12,
      bottom: 120,
      child: Column(
        children: [
          // Profile Avatar
          _buildProfileButton(),
          const SizedBox(height: 24),

          // Like
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(_likeCount),
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _toggleLike,
          ),
          const SizedBox(height: 20),

          // Comment
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.reel.commentCount),
            onTap: widget.onComment,
          ),
          const SizedBox(height: 20),

          // Share
          _buildActionButton(
            icon: Icons.send,
            label: 'Paylaş',
            onTap: widget.onShare,
          ),
          const SizedBox(height: 20),

          // Sound Disc
          _buildSoundDisc(),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: widget.reel.userAvatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.reel.userAvatarUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
            ),
          ),
          // Follow button
          if (!widget.reel.isFollowing)
            Positioned(
              bottom: -8,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: widget.onFollow,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
            shadows: const [Shadow(blurRadius: 8, color: Colors.black45)],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundDisc() {
    return GestureDetector(
      onTap: widget.onSoundTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600, width: 8),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: widget.reel.soundImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.reel.soundImageUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey.shade800,
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Row(
              children: [
                Text(
                  '@${widget.reel.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
                if (widget.reel.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified, color: Colors.blue, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            widget.reel.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
          const SizedBox(height: 12),

          // Sound/Music info
          GestureDetector(
            onTap: widget.onSoundTap,
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.reel.soundName ??
                        'Orijinal ses - ${widget.reel.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.5), Colors.transparent],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Reel data model
class ReelData {
  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String description;
  final String? soundName;
  final String? soundImageUrl;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFollowing;
  final bool isVerified;

  const ReelData({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    this.thumbnailUrl,
    this.videoUrl,
    required this.description,
    this.soundName,
    this.soundImageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isFollowing = false,
    this.isVerified = false,
  });
}
