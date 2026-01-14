import 'dart:ui';
import 'package:flutter/material.dart';
import '../features/wallpapers/screens/wallpapers_screen.dart';
import '../features/weather/screens/weather_screen.dart';
import '../features/news/screens/news_screen.dart';

/// Apps Hub Screen - Super App Uygulama Merkezi
///
/// Glassmorphism tasarımlı, 11 API için grid yapısında merkez ekran.
class AppsHubScreen extends StatefulWidget {
  const AppsHubScreen({super.key});

  @override
  State<AppsHubScreen> createState() => _AppsHubScreenState();
}

class _AppsHubScreenState extends State<AppsHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<AppItem> _apps = [
    AppItem(
      name: 'Hava Durumu',
      icon: Icons.wb_sunny_rounded,
      gradient: [Color(0xFF4A90D9), Color(0xFF48C6EF)],
      description: 'Anlık hava durumu',
      isAvailable: true,
      route: const WeatherScreen(),
    ),
    AppItem(
      name: 'Galeri',
      icon: Icons.photo_library_rounded,
      gradient: [Color(0xFFE91E63), Color(0xFFFF5722)],
      description: 'Unsplash fotoğraflar',
      isAvailable: true,
      route: const WallpapersScreen(),
    ),
    AppItem(
      name: 'Haberler',
      icon: Icons.newspaper_rounded,
      gradient: [Color(0xFF2196F3), Color(0xFF03A9F4)],
      description: 'Güncel haberler',
      isAvailable: true,
      route: const NewsScreen(),
    ),
    AppItem(
      name: 'Kripto',
      icon: Icons.currency_bitcoin_rounded,
      gradient: [Color(0xFFF7931A), Color(0xFFFFD700)],
      description: 'Kripto paralar',
      isAvailable: false,
    ),
    AppItem(
      name: 'Sohbet Botu',
      icon: Icons.smart_toy_rounded,
      gradient: [Color(0xFF10A37F), Color(0xFF00D4AA)],
      description: 'AI asistan',
      isAvailable: false,
    ),
    AppItem(
      name: 'Haritalar',
      icon: Icons.map_rounded,
      gradient: [Color(0xFF4285F4), Color(0xFF34A853)],
      description: 'Dünya haritası',
      isAvailable: false,
    ),
    AppItem(
      name: 'Ülkeler',
      icon: Icons.public_rounded,
      gradient: [Color(0xFF8E44AD), Color(0xFF3498DB)],
      description: 'Ülke bilgileri',
      isAvailable: false,
    ),
    AppItem(
      name: 'AI Modeller',
      icon: Icons.psychology_rounded,
      gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
      description: 'Hugging Face',
      isAvailable: false,
    ),
    AppItem(
      name: 'Borsa',
      icon: Icons.show_chart_rounded,
      gradient: [Color(0xFF00C853), Color(0xFFFF5252)],
      description: 'Hisse senetleri',
      isAvailable: false,
    ),
    AppItem(
      name: 'Döviz',
      icon: Icons.currency_exchange_rounded,
      gradient: [Color(0xFF1ABC9C), Color(0xFF16A085)],
      description: 'Döviz çevirici',
      isAvailable: false,
    ),
    AppItem(
      name: 'Görsel Üret',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFF9B59B6), Color(0xFFE74C3C)],
      description: 'AI ile resim',
      isAvailable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Animated Gradient Background
          _buildAnimatedBackground(),

          // Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader()),

                // Apps Grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAppCard(_apps[index], index),
                      childCount: _apps.length,
                    ),
                  ),
                ),

                // Footer space
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
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
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 20),
          ),
          onPressed: () {
            // TODO: Settings
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFF764BA2),
                  const Color(0xFFf093fb),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFFf093fb),
                  const Color(0xFF667EEA),
                  _animation.value,
                )!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Super App',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '11 güçlü uygulama tek bir yerde',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),

          // Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Aktif', '3', Icons.check_circle_outline),
                _buildDivider(),
                _buildStat('Yakında', '8', Icons.access_time),
                _buildDivider(),
                _buildStat('API', '11', Icons.api),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildAppCard(AppItem app, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _onAppTap(app),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(app.isAvailable ? 0.25 : 0.1),
                    Colors.white.withOpacity(app.isAvailable ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(app.isAvailable ? 0.3 : 0.1),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Background Icon
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Icon(
                      app.icon,
                      size: 80,
                      color: app.gradient.first.withOpacity(0.15),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: app.isAvailable
                                  ? app.gradient
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade600,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: app.isAvailable
                                ? [
                                    BoxShadow(
                                      color: app.gradient.first.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(app.icon, color: Colors.white, size: 22),
                        ),

                        const Spacer(),

                        // App Name
                        Text(
                          app.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: app.isAvailable
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Description or Coming Soon
                        Text(
                          app.isAvailable ? app.description : 'Yakında',
                          style: TextStyle(
                            fontSize: 10,
                            color: app.isAvailable
                                ? Colors.white.withOpacity(0.7)
                                : Colors.white.withOpacity(0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Lock Icon for unavailable
                  if (!app.isAvailable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white54,
                          size: 14,
                        ),
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

  void _onAppTap(AppItem app) {
    if (!app.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white),
              const SizedBox(width: 12),
              Text('${app.name} yakında kullanıma açılacak!'),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (app.route != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => app.route!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }
}

/// Uygulama Öğesi Modeli
class AppItem {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final String description;
  final bool isAvailable;
  final Widget? route;

  AppItem({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.description,
    this.isAvailable = false,
    this.route,
  });
}
