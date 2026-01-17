import 'package:flutter/material.dart';

/// StoryItem - Instagram tarzı hikaye dairesi
///
/// Features:
/// - Gradient border (görülmemiş hikayeler için)
/// - Gri border (görülmüş hikayeler için)
/// - Avatar gösterimi
/// - Kullanıcı adı
/// - Hikaye ekle modu
class StoryItem extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool hasUnviewedStory;
  final bool isAddButton;
  final VoidCallback? onTap;

  const StoryItem({
    super.key,
    this.avatarUrl,
    required this.username,
    this.hasUnviewedStory = true,
    this.isAddButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with Ring
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _getRingGradient(),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person,
                              color: Colors.grey.shade400,
                              size: 30,
                            )
                          : null,
                    ),
                    // Add Button Overlay
                    if (isAddButton)
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
            // Username
            Text(
              isAddButton ? 'Hikayem' : username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Gradient _getRingGradient() {
    if (isAddButton) {
      return LinearGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (hasUnviewedStory) {
      // Instagram-style gradient
      return const LinearGradient(
        colors: [
          Color(0xFFFBAA47), // Orange
          Color(0xFFDD2A7B), // Red
          Color(0xFFA60F93), // Purple
          Color(0xFF515BD4), // Blue
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
    }

    // Viewed - grey ring
    return LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]);
  }
}

/// StoriesBar - Yatay kaydırılabilir hikaye listesi
class StoriesBar extends StatelessWidget {
  final List<StoryData> stories;
  final String? currentUserAvatarUrl;
  final VoidCallback? onAddStory;
  final Function(StoryData)? onStoryTap;

  const StoriesBar({
    super.key,
    required this.stories,
    this.currentUserAvatarUrl,
    this.onAddStory,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: stories.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Hikaye Ekle
            return StoryItem(
              avatarUrl: currentUserAvatarUrl,
              username: 'Hikayem',
              isAddButton: true,
              onTap: onAddStory,
            );
          }

          final story = stories[index - 1];
          return StoryItem(
            avatarUrl: story.avatarUrl,
            username: story.username,
            hasUnviewedStory: story.hasUnviewed,
            onTap: () => onStoryTap?.call(story),
          );
        },
      ),
    );
  }
}

/// Story data model
class StoryData {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool hasUnviewed;

  const StoryData({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.hasUnviewed = true,
  });
}
