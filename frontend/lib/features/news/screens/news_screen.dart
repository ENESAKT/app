import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

/// News Screen - Haber Akışı Ekranı
///
/// Kaydırılabilir haber kartları olan modern bir haber akışı.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  final NewsService _service = NewsService();
  late TabController _tabController;

  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  NewsCategory _selectedCategory = NewsCategory.general;

  final List<NewsCategory> _categories = NewsCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _categories[_tabController.index];
      });
      _loadNews();
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final articles = await _service.getTopHeadlines(
        category: _selectedCategory,
        pageSize: 30,
      );

      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _buildSliverAppBar(),
          _buildCategoryTabs(),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F1419),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF03A9F4)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.newspaper,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Güncel Haberler',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Türkiye ve dünyadan son dakika haberleri',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF2196F3),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: _categories.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji),
                  const SizedBox(width: 6),
                  Text(cat.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_articles.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      color: const Color(0xFF2196F3),
      child: CustomScrollView(
        slivers: [
          // Featured Article (First one)
          if (_articles.isNotEmpty)
            SliverToBoxAdapter(child: _buildFeaturedArticle(_articles.first)),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Son Haberler',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Articles List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                // Skip first article (featured)
                final articleIndex = index + 1;
                if (articleIndex >= _articles.length) return null;
                return _buildArticleCard(_articles[articleIndex]);
              }, childCount: _articles.length - 1),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          SizedBox(height: 16),
          Text(
            'Haberler yükleniyor...',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Haberler yüklenemedi',
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
              onPressed: _loadNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Haber bulunamadı',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedArticle(NewsArticle article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (article.urlToImage != null)
                CachedNetworkImage(
                  imageUrl: article.urlToImage!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Icon(
                      Icons.newspaper,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    ),
                  ),
                  child: const Icon(
                    Icons.newspaper,
                    color: Colors.white24,
                    size: 48,
                  ),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedCategory.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Source & Time
                    Row(
                      children: [
                        const Icon(
                          Icons.source,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.source,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.publishedTimeAgo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Featured Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.whatshot, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'MANŞET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 120,
                height: 100,
                child: article.urlToImage != null
                    ? CachedNetworkImage(
                        imageUrl: article.urlToImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade800),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF262D40),
                          child: const Icon(
                            Icons.newspaper,
                            color: Colors.white24,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF262D40),
                        child: const Icon(
                          Icons.newspaper,
                          color: Colors.white24,
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Source & Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            article.source,
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          article.publishedTimeAgo,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow Icon
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openArticle(NewsArticle article) async {
    if (await canLaunchUrl(Uri.parse(article.url))) {
      await launchUrl(
        Uri.parse(article.url),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

/// Tab Bar Delegate for Sliver Persistent Header
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFF0F1419), child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
