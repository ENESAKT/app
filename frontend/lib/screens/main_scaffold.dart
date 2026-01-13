import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/update_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'create_post_screen.dart';
import 'conversations_screen.dart';
import 'profile_screen.dart';

/// MainScaffold - 5 Sekmeli Instagram tarzı ana layout
///
/// Architecture:
/// - IndexedStack ile state koruması
/// - NotificationService realtime dinleme
/// - UpdateService güncelleme kontrolü
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final UpdateService _updateService = UpdateService();
  final NotificationService _notificationService = NotificationService();

  // Ekranlar - IndexedStack ile state korunur
  late final List<Widget> _screens;

  // Renk paleti
  static const Color _activeColor = Colors.deepPurple;
  static const Color _inactiveColor = Colors.grey;

  @override
  void initState() {
    super.initState();

    _screens = [
      const HomeScreen(),
      const ExploreScreen(),
      const SizedBox(), // Create - özel handling
      const ConversationsScreen(),
      const _ProfileWrapper(),
    ];

    // Servisleri başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateService.init(context);

      final userId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).firebaseUser?.uid;
      if (userId != null) {
        _notificationService.startListening(userId);
      }
    });
  }

  @override
  void dispose() {
    _updateService.dispose();
    _notificationService.stopListening();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Create tab - modal olarak aç
      _openCreatePost();
      return;
    }

    setState(() => _currentIndex = index);
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Ana Sayfa'),
              _buildNavItem(1, Icons.search_outlined, Icons.search, 'Keşfet'),
              _buildAddButton(),
              _buildNavItem(
                3,
                Icons.chat_bubble_outline,
                Icons.chat_bubble,
                'Mesajlar',
              ),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 26,
              color: isActive ? _activeColor : _inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? _activeColor : _inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _openCreatePost,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Profile Wrapper - Current user profili
class _ProfileWrapper extends StatelessWidget {
  const _ProfileWrapper();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.firebaseUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return ProfileScreen(userId: userId, isCurrentUser: true);
  }
}
