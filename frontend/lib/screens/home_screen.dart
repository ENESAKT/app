import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/story_model.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';
import '../widgets/post_widget.dart';
import '../widgets/story_circle.dart';
import '../widgets/comment_sheet.dart';

/// HomeScreen - Ana akış ekranı (Feed)
///
/// Features:
/// - Stories bar (üstte)
/// - Post akışı (takip edilenler)
/// - Pull-to-refresh
/// - Infinite scroll
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();
  final ScrollController _scrollController = ScrollController();

  List<PostModel> _posts = [];
  List<UserStories> _stories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _currentUserId;

  // Pagination
  static const int _pageSize = 20;
  int _offset = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      // Paralel yükleme
      final results = await Future.wait([
        _postService.getFeed(
          userId: _currentUserId!,
          limit: _pageSize,
          offset: 0,
        ),
        _storyService.getStoryFeed(_currentUserId!),
      ]);

      setState(() {
        _posts = results[0] as List<PostModel>;
        _stories = results[1] as List<UserStories>;
        _offset = _posts.length;
        _hasMore = _posts.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Feed yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _currentUserId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final newPosts = await _postService.getFeed(
        userId: _currentUserId!,
        limit: _pageSize,
        offset: _offset,
      );

      setState(() {
        _posts.addAll(newPosts);
        _offset += newPosts.length;
        _hasMore = newPosts.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('❌ Daha fazla post yükleme hatası: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _offset = 0;
    _hasMore = true;
    await _loadInitialData();
  }

  void _handleLike(int index) async {
    final post = _posts[index];

    // Optimistic UI update
    setState(() {
      _posts[index] = post.copyWith(
        isLiked: !post.isLiked,
        likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
      );
    });

    // Backend sync
    final success = await _postService.toggleLike(
      postId: post.id,
      userId: _currentUserId!,
      isLiked: post.isLiked,
    );

    // Rollback on error
    if (!success) {
      setState(() {
        _posts[index] = post;
      });
    }
  }

  void _handleSave(int index) async {
    final post = _posts[index];

    // Optimistic UI update
    setState(() {
      _posts[index] = post.copyWith(isSaved: !post.isSaved);
    });

    // Backend sync
    final success = await _postService.toggleSave(
      postId: post.id,
      userId: _currentUserId!,
      isSaved: post.isSaved,
    );

    // Rollback on error
    if (!success) {
      setState(() {
        _posts[index] = post;
      });
    }
  }

  void _openComments(PostModel post) async {
    // Yorumları yükle
    final comments = await _postService.getComments(postId: post.id);

    if (!mounted) return;

    CommentSheet.show(
      context: context,
      postId: post.id,
      comments: comments,
      onAddComment: (content, {String? parentId}) async {
        final newComment = await _postService.addComment(
          postId: post.id,
          userId: _currentUserId!,
          content: content,
          parentId: parentId,
        );

        if (newComment != null) {
          // Comment count güncelle
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            setState(() {
              _posts[index] = _posts[index].copyWith(
                commentCount: _posts[index].commentCount + 1,
              );
            });
          }
        }
      },
    );
  }

  void _openProfile(String userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  void _openStory(UserStories userStory) {
    // TODO: Story Viewer açılacak
    print('Story açılıyor: ${userStory.username}');
  }

  void _addStory() {
    // TODO: Story ekleme ekranı
    print('Story ekle');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Stories Bar
          SliverToBoxAdapter(child: _buildStoriesBar()),
          // Divider
          const SliverToBoxAdapter(child: Divider(height: 1)),
          // Posts
          if (_posts.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _posts.length) {
                  return _isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                return PostWidget(
                  post: _posts[index],
                  onLike: () => _handleLike(index),
                  onSave: () => _handleSave(index),
                  onComment: () => _openComments(_posts[index]),
                  onProfileTap: () => _openProfile(_posts[index].userId),
                  onShare: () {
                    // TODO: Share işlemi
                  },
                );
              }, childCount: _posts.length + 1),
            ),
        ],
      ),
    );
  }

  Widget _buildStoriesBar() {
    // Current user story data
    StoryData? currentUserStory;
    final myStories = _stories
        .where((s) => s.userId == _currentUserId)
        .toList();
    if (myStories.isNotEmpty) {
      final userStory = myStories.first;
      currentUserStory = StoryData(
        id: userStory.stories.first.id,
        userId: userStory.userId,
        username: 'Hikayem',
        avatarUrl: userStory.avatarUrl,
        hasUnviewed: userStory.hasUnviewed,
        hasStory: true,
        storyCount: userStory.count,
      );
    }

    // Other users' stories
    final otherStories = _stories
        .where((s) => s.userId != _currentUserId)
        .map(
          (s) => StoryData(
            id: s.stories.first.id,
            userId: s.userId,
            username: s.username ?? 'Kullanıcı',
            avatarUrl: s.avatarUrl,
            hasUnviewed: s.hasUnviewed,
            storyCount: s.count,
          ),
        )
        .toList();

    return StoriesBar(
      stories: otherStories,
      currentUserStory: currentUserStory,
      onAddStory: _addStory,
      onStoryTap: (story) {
        final userStory = _stories.firstWhere(
          (s) => s.userId == story.userId,
          orElse: () => _stories.first,
        );
        _openStory(userStory);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz paylaşım yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Takip ettiğin kişilerin paylaşımları burada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/explore'),
              icon: const Icon(Icons.search),
              label: const Text('Keşfet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
