import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/update_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'conversations_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Ana Layout - 5 Sekmeli Bottom Navigation
/// Instagram/TikTok tarzı modern sosyal medya navigasyonu
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final UpdateService _updateService = UpdateService();

  // Sayfalar
  final List<Widget> _pages = [
    const HomeScreen(), // 🏠 Akış
    const SearchScreen(), // 🔍 Keşfet
    const _AddPostPlaceholder(), // ➕ Paylaş (placeholder)
    const ConversationsScreen(), // 💬 Mesajlar
    const _ProfilePage(), // 👤 Profil
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateService.init(context);
    });
  }

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      // Drawer (Yan Menü)
      drawer: _buildDrawer(auth),

      // App Bar
      appBar: AppBar(
        title: _getTitle(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/friends'),
          ),
        ],
      ),

      // Body
      body: IndexedStack(index: _currentIndex, children: _pages),

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),

      // FAB for Add (ortadaki büyük buton)
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _currentIndex = 2),
              backgroundColor: Colors.deepPurple,
              elevation: 8,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _getTitle() {
    switch (_currentIndex) {
      case 0:
        return const Text(
          'Arkadaşlık',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      case 1:
        return const Text('Keşfet');
      case 2:
        return const Text('Paylaş');
      case 3:
        return const Text('Mesajlar');
      case 4:
        return const Text('Profil');
      default:
        return const Text('Arkadaşlık');
    }
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 10,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Ana Sayfa'),
            _buildNavItem(1, Icons.search_outlined, Icons.search, 'Keşfet'),
            const SizedBox(width: 48), // FAB için boşluk
            _buildNavItem(
              3,
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              'Mesaj',
            ),
            _buildNavItem(4, Icons.person_outline, Icons.person, 'Profil'),
          ],
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
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.deepPurple : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white24,
                  backgroundImage: auth.currentUser?.profilePhoto != null
                      ? NetworkImage(auth.currentUser!.profilePhoto!)
                      : null,
                  child: auth.currentUser?.profilePhoto == null
                      ? Text(
                          (auth.currentUser?.username ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  auth.currentUser?.username ?? 'Kullanıcı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  auth.currentUser?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Menu Items
          ListTile(
            leading: const Icon(Icons.people, color: Colors.deepPurple),
            title: const Text('Arkadaşlarım'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.deepPurple),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
            title: const Text('Hakkında'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await auth.signOut();
            },
          ),

          const Spacer(),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0 • Made with 💜',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Arkadaşlık',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.people, color: Colors.white, size: 40),
      ),
      children: [const Text('Modern sosyal medya ve arkadaşlık uygulaması.')],
    );
  }
}

/// Paylaş Placeholder
class _AddPostPlaceholder extends StatelessWidget {
  const _AddPostPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate,
              size: 80,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bir şeyler paylaş!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf, düşünce veya durum paylaşabilirsin',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Post oluşturma ekranına git
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Fotoğraf Çek'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil Sayfası Wrapper
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.userId; // Supabase UUID

    if (userId == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return ProfileScreen(userId: userId, isCurrentUser: true);
  }
}
