import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/unsplash_photo.dart';
import '../services/unsplash_service.dart';
import 'photo_detail_screen.dart';

/// Wallpapers Screen - Unsplash Fotoğraf Galerisi
///
/// Masonry (şelale) görünümünde, arama yapılabilen şık bir galeri.
class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  final UnsplashService _service = UnsplashService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<UnsplashPhoto> _photos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _photos = [];
      });
    }

    setState(() {
      _isLoading = _photos.isEmpty;
      _hasError = false;
    });

    try {
      List<UnsplashPhoto> newPhotos;

      if (_searchQuery.isNotEmpty) {
        final result = await _service.searchPhotos(
          _searchQuery,
          page: _currentPage,
          perPage: 20,
        );
        newPhotos = result.photos;
      } else {
        newPhotos = await _service.getPhotos(page: _currentPage, perPage: 20);
      }

      setState(() {
        if (refresh || _currentPage == 1) {
          _photos = newPhotos;
        } else {
          _photos.addAll(newPhotos);
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = _photos.isEmpty;
        _errorMessage = e.toString();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadMorePhotos() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadPhotos();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _photos = [];
    });
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _buildSliverAppBar(),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Duvar Kağıdı Galerisi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unsplash\'tan yüksek kaliteli fotoğraflar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildSearchBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Fotoğraf ara...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.5),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onSubmitted: _onSearch,
          onChanged: (value) {
            setState(() {});
            if (value.isEmpty) {
              _onSearch('');
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _photos.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError && _photos.isEmpty) {
      return _buildErrorState();
    }

    if (_photos.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPhotoGrid();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFE91E63)),
          SizedBox(height: 16),
          Text(
            'Fotoğraflar yükleniyor...',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadPhotos(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? '"$_searchQuery" için sonuç bulunamadı'
                : 'Fotoğraf bulunamadı',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return RefreshIndicator(
      onRefresh: () => _loadPhotos(refresh: true),
      color: const Color(0xFFE91E63),
      child: CustomScrollView(
        slivers: [
          // Masonry-like Grid with variable heights
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < _photos.length) {
                  return _buildPhotoCard(_photos[index], index);
                }
                return null;
              }, childCount: _photos.length),
            ),
          ),

          // Loading More Indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                ),
              ),
            ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(UnsplashPhoto photo, int index) {
    // Alternate heights for masonry effect
    final isEven = index % 2 == 0;
    final heightFactor = isEven ? 1.3 : 1.0;

    return GestureDetector(
      onTap: () => _openPhotoDetail(photo),
      child: Hero(
        tag: 'photo_${photo.id}',
        child: Container(
          height: 200 * heightFactor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: photo.urls.regular,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Color(photo.colorValue),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
                ),

                // Gradient Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // User Avatar
                        if (photo.user.profileImage != null)
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: CachedNetworkImageProvider(
                              photo.user.profileImage!,
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Username
                        Expanded(
                          child: Text(
                            photo.user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Likes
                        const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(photo.likes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPhotoDetail(UnsplashPhoto photo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhotoDetailScreen(photo: photo)),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
