import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/user_tile.dart';

/// ExploreScreen - Keşfet ekranı
///
/// Features:
/// - Arama (kullanıcı/etiket)
/// - Popüler postlar grid
/// - Post detay görünümü
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PostModel> _posts = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 30;
  int _offset = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final posts = await _postService.getExplorePosts(
        limit: _pageSize,
        offset: 0,
      );

      setState(() {
        _posts = posts;
        _offset = posts.length;
        _hasMore = posts.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Explore yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _isSearching) return;

    setState(() => _isLoadingMore = true);

    try {
      final newPosts = await _postService.getExplorePosts(
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

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('users')
          .select('id, username, avatar_url, bio')
          .ilike('username', '%$query%')
          .limit(20);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('❌ Arama hatası: $e');
    }
  }

  void _openPost(PostModel post) {
    // TODO: Post detay ekranına git
    print('Post açılıyor: ${post.id}');
  }

  void _openProfile(String userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),
        // Content
        Expanded(child: _isSearching ? _buildSearchResults() : _buildGrid()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ara',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => _search(value),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return UserTile(
          userId: user['id'] ?? '',
          username: user['username'] ?? 'Kullanıcı',
          avatarUrl: user['avatar_url'],
          subtitle: user['bio'],
          showFollowButton: false,
          onTap: () => _openProfile(user['id']),
        );
      },
    );
  }

  Widget _buildGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Keşfedilecek içerik yok',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _offset = 0;
        _hasMore = true;
        await _loadPosts();
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          return _buildGridItem(_posts[index]);
        },
      ),
    );
  }

  Widget _buildGridItem(PostModel post) {
    return GestureDetector(
      onTap: () => _openPost(post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          post.primaryMediaUrl != null
              ? Image.network(
                  post.primaryMediaUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                )
              : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
          // Carousel indicator
          if (post.isCarousel)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.collections,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          // Video indicator
          if (post.mediaType == MediaType.video)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
