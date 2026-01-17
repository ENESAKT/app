import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/update_service.dart';
import '../services/notification_service.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reels/screens/reels_screen.dart';
import 'explore_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'conversations_screen.dart';

/// MainScaffold - Premium Dark Theme ile 5 Sekmeli Ana Layout
///
/// Architecture:
/// - IndexedStack ile state koruması
/// - Glassmorphism bottom navigation bar (Dark theme)
/// - Gradient aktif ikonlar (Mor-Turuncu)
/// - NotificationService realtime dinleme
/// - UpdateService güncelleme kontrolü
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final UpdateService _updateService = UpdateService();
  final NotificationService _notificationService = NotificationService();

  // Animasyon controller'ları
  late List<AnimationController> _iconAnimControllers;

  // Ekranlar - IndexedStack ile state korunur
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      const FeedHomeScreen(), // 0: Ana Sayfa
      const ReelsScreen(), // 1: Reels
      const SizedBox(), // 2: Create - özel handling
      const ConversationsScreen(), // 3: Chat
      const _ProfileWrapper(), // 4: Profil
    ];

    // İkon animasyonları
    _iconAnimControllers = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

    // Servisleri başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateService.init(context);

      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId != null) {
        _notificationService.startListening(userId);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _iconAnimControllers) {
      controller.dispose();
    }
    _updateService.dispose();
    _notificationService.stopListening();
    super.dispose();
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();

    if (index == 2) {
      // Create tab - modal olarak aç
      _openCreatePost();
      return;
    }

    // Animasyon
    _iconAnimControllers[index].forward().then((_) {
      _iconAnimControllers[index].reverse();
    });

    setState(() => _currentIndex = index);
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreatePostScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      extendBody: true, // Glassmorphism için
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildGlassmorphismNav(),
    );
  }

  /// Glassmorphism alt navigasyon çubuğu - Dark Theme
  Widget _buildGlassmorphismNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 80 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle_filled,
                  label: 'Reels',
                ),
                _buildAddButton(),
                _buildNavItem(
                  index: 3,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Mesajlar',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _iconAnimControllers[index],
        builder: (context, child) {
          final scale = 1.0 + (_iconAnimControllers[index].value * 0.15);
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon - Gradient veya Normal
                  isActive
                      ? ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
                          ).createShader(bounds),
                          child: Icon(
                            activeIcon,
                            size: 28,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 26,
                          color: Colors.white.withOpacity(0.5),
                        ),
                  const SizedBox(height: 4),
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _openCreatePost,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

/// AnimatedBuilder helper
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(listenable: animation, builder: builder);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required super.listenable,
    required this.builder,
  }) : super();

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

/// Profile Wrapper - Current user profili
class _ProfileWrapper extends StatelessWidget {
  const _ProfileWrapper();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.userId;

    if (userId == null) {
      return Container(
        color: const Color(0xFF0D0D0D),
        child: const Center(
          child: Text(
            'Kullanıcı bulunamadı',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ProfileScreen(userId: userId, isCurrentUser: true);
  }
}
