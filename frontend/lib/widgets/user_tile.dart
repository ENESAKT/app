import 'package:flutter/material.dart';

/// UserTile - Kullanıcı listesi bileşeni
///
/// Uses:
/// - Followers/Following listesi
/// - Arama sonuçları
/// - Önerilen kullanıcılar
class UserTile extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? subtitle;
  final bool isFollowing;
  final bool showFollowButton;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onFollowTap;

  const UserTile({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.subtitle,
    this.isFollowing = false,
    this.showFollowButton = true,
    this.isVerified = false,
    this.onTap,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        backgroundColor: Colors.grey.shade200,
        child: avatarUrl == null
            ? Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 14, color: Colors.blue),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: showFollowButton ? _buildFollowButton() : null,
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onFollowTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white : Colors.deepPurple,
          foregroundColor: isFollowing ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: isFollowing
              ? BorderSide(color: Colors.grey.shade300)
              : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          isFollowing ? 'Takipte' : 'Takip Et',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Compact User Avatar Row (for mutual followers, etc.)
class UserAvatarRow extends StatelessWidget {
  final List<String?> avatarUrls;
  final int maxDisplay;
  final int? remainingCount;
  final double avatarSize;
  final VoidCallback? onTap;

  const UserAvatarRow({
    super.key,
    required this.avatarUrls,
    this.maxDisplay = 3,
    this.remainingCount,
    this.avatarSize = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = avatarUrls.length > maxDisplay
        ? maxDisplay
        : avatarUrls.length;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width:
            avatarSize +
            (displayCount - 1) * (avatarSize * 0.6) +
            (remainingCount != null && remainingCount! > 0 ? 30 : 0),
        height: avatarSize,
        child: Stack(
          children: [
            for (int i = 0; i < displayCount; i++)
              Positioned(
                left: i * (avatarSize * 0.6),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: avatarSize / 2 - 2,
                    backgroundImage: avatarUrls[i] != null
                        ? NetworkImage(avatarUrls[i]!)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: avatarUrls[i] == null
                        ? Icon(Icons.person, size: avatarSize / 2)
                        : null,
                  ),
                ),
              ),
            if (remainingCount != null && remainingCount! > 0)
              Positioned(
                left: displayCount * (avatarSize * 0.6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(avatarSize / 2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: TextStyle(
                        fontSize: avatarSize * 0.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Suggestion Card - Önerilen kullanıcı kartı
class SuggestionCard extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? reason;
  final bool isFollowing;
  final VoidCallback? onTap;
  final VoidCallback? onFollowTap;
  final VoidCallback? onDismiss;

  const SuggestionCard({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.reason,
    this.isFollowing = false,
    this.onTap,
    this.onFollowTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dismiss button
          if (onDismiss != null)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              ),
            ),
          // Avatar
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 40,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              backgroundColor: Colors.grey.shade200,
              child: avatarUrl == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // Username
          Text(
            username,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Reason
          if (reason != null) ...[
            const SizedBox(height: 2),
            Text(
              reason!,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          // Follow Button
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: onFollowTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.white : Colors.deepPurple,
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                elevation: 0,
                side: isFollowing
                    ? BorderSide(color: Colors.grey.shade300)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isFollowing ? 'Takipte' : 'Takip Et',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
