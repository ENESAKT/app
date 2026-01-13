import 'package:flutter/material.dart';

/// StoryCircle - Story avatar bileşeni
///
/// Features:
/// - Gradient ring (görüntülenmemiş)
/// - Grey ring (görüntülenmiş)
/// - Add story butonu (kendi için)
/// - Küçük ve büyük boyut desteği
class StoryCircle extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool hasUnviewedStory;
  final bool isAddButton;
  final bool isSmall;
  final VoidCallback? onTap;

  const StoryCircle({
    super.key,
    this.avatarUrl,
    required this.username,
    this.hasUnviewedStory = false,
    this.isAddButton = false,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isSmall ? 56 : 68;
    final double avatarRadius = isSmall ? 24 : 30;
    final double ringWidth = isSmall ? 2 : 3;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with Ring
            Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(ringWidth),
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
                      radius: avatarRadius,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: avatarUrl == null
                          ? Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: isSmall ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            )
                          : null,
                    ),
                    // Add Button Overlay
                    if (isAddButton)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: isSmall ? 18 : 22,
                          height: isSmall ? 18 : 22,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: isSmall ? 12 : 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Username
            Text(
              isAddButton ? 'Hikayem' : username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmall ? 11 : 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Gradient? _getRingGradient() {
    if (isAddButton) {
      // Add button - subtle gradient
      return LinearGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (hasUnviewedStory) {
      // Instagram-style gradient for unviewed stories
      return const LinearGradient(
        colors: [
          Color(0xFFFBAA47), // Orange
          Color(0xFFD91A46), // Red
          Color(0xFFA60F93), // Purple
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
    }

    // Viewed stories - grey ring
    return LinearGradient(
      colors: [Colors.grey.shade300, Colors.grey.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// Stories Bar - Story listesi
class StoriesBar extends StatelessWidget {
  final List<StoryData> stories;
  final StoryData? currentUserStory;
  final VoidCallback? onAddStory;
  final Function(StoryData story)? onStoryTap;

  const StoriesBar({
    super.key,
    required this.stories,
    this.currentUserStory,
    this.onAddStory,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: stories.length + 1, // +1 for current user
        itemBuilder: (context, index) {
          if (index == 0) {
            // Current user's story or Add button
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: StoryCircle(
                avatarUrl: currentUserStory?.avatarUrl,
                username: currentUserStory?.username ?? 'Sen',
                hasUnviewedStory: currentUserStory?.hasUnviewed ?? false,
                isAddButton:
                    currentUserStory == null || !currentUserStory!.hasStory,
                onTap: currentUserStory?.hasStory == true
                    ? () => onStoryTap?.call(currentUserStory!)
                    : onAddStory,
              ),
            );
          }

          final story = stories[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StoryCircle(
              avatarUrl: story.avatarUrl,
              username: story.username,
              hasUnviewedStory: story.hasUnviewed,
              onTap: () => onStoryTap?.call(story),
            ),
          );
        },
      ),
    );
  }
}

/// Story data model (UI için basitleştirilmiş)
class StoryData {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool hasUnviewed;
  final bool hasStory;
  final int storyCount;

  const StoryData({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.hasUnviewed = false,
    this.hasStory = true,
    this.storyCount = 1,
  });
}
