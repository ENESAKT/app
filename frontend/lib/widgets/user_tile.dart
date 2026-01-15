import 'package:flutter/material.dart';

/// Arkadaşlık durumu enum
enum FriendStatus {
  none, // Henüz arkadaş değil
  pending, // İstek gönderildi (beklemede)
  received, // İstek geldi (kabul bekliyor)
  friends, // Arkadaşlar
}

/// UserTile - Kullanıcı listesi bileşeni
///
/// Uses:
/// - Followers/Following listesi
/// - Arama sonuçları
/// - Önerilen kullanıcılar
/// - Keşfet sayfası
class UserTile extends StatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? subtitle;
  final FriendStatus friendStatus;
  final bool showFriendButton;
  final bool isVerified;
  final VoidCallback? onTap;
  final Future<void> Function()? onFriendAction;

  const UserTile({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.subtitle,
    this.friendStatus = FriendStatus.none,
    this.showFriendButton = true,
    this.isVerified = false,
    this.onTap,
    this.onFriendAction,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  bool _isLoading = false;
  late FriendStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.friendStatus;
  }

  @override
  void didUpdateWidget(UserTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friendStatus != widget.friendStatus) {
      _currentStatus = widget.friendStatus;
    }
  }

  Future<void> _handleFriendAction() async {
    if (_isLoading || widget.onFriendAction == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onFriendAction!();
      // Status güncelleme: none -> pending
      if (_currentStatus == FriendStatus.none) {
        setState(() => _currentStatus = FriendStatus.pending);
      }
    } catch (e) {
      print('❌ Friend action error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GestureDetector(
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: 24,
          backgroundImage: widget.avatarUrl != null
              ? NetworkImage(widget.avatarUrl!)
              : null,
          backgroundColor: Colors.grey.shade200,
          child: widget.avatarUrl == null
              ? Text(
                  widget.username.isNotEmpty
                      ? widget.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                )
              : null,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              widget.username,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 14, color: Colors.blue),
          ],
        ],
      ),
      subtitle: widget.subtitle != null
          ? Text(
              widget.subtitle!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: widget.showFriendButton ? _buildFriendButton() : null,
    );
  }

  Widget _buildFriendButton() {
    // İkon ve stil seçimi
    IconData icon;
    Color bgColor;
    Color iconColor;
    String? tooltip;

    switch (_currentStatus) {
      case FriendStatus.friends:
        icon = Icons.check_circle;
        bgColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        tooltip = 'Arkadaşsınız';
        break;
      case FriendStatus.pending:
        icon = Icons.hourglass_empty;
        bgColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        tooltip = 'İstek Gönderildi';
        break;
      case FriendStatus.received:
        icon = Icons.person_add;
        bgColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
        tooltip = 'İsteği Kabul Et';
        break;
      case FriendStatus.none:
        icon = Icons.person_add_alt_1;
        bgColor = Colors.deepPurple.withOpacity(0.1);
        iconColor = Colors.deepPurple;
        tooltip = 'Arkadaş Ekle';
    }

    // Loading durumu
    if (_isLoading) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Arkadaşsa sadece göster, tıklanamaz
    if (_currentStatus == FriendStatus.friends) {
      return Tooltip(
        message: tooltip,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      );
    }

    // Tıklanabilir buton
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _handleFriendAction,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
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
                isFollowing ? 'Arkadaşsınız' : 'Arkadaş Ekle',
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
