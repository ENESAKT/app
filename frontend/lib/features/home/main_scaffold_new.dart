import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../screens/search_screen.dart';
import '../../screens/conversations_screen.dart';
import '../../screens/profile_screen.dart';
import 'home_view.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MAIN SCAFFOLD - Uygulama Ana İskeleti
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Glassmorphism Bottom Navigation Bar ile modern navigasyon yapısı.
/// 5 Ana Sekme: Anasayfa, Keşfet, Oluştur, Mesajlar, Profil

class MainScaffoldNew extends ConsumerStatefulWidget {
  const MainScaffoldNew({super.key});

  @override
  ConsumerState<MainScaffoldNew> createState() => _MainScaffoldNewState();
}

class _MainScaffoldNewState extends ConsumerState<MainScaffoldNew> {
  // Seçili sekme indeksi
  int _selectedIndex = 0;

  // Sayfa controller (animasyonlu geçişler için)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Sekme değiştiğinde
  void _onTabTapped(int index) {
    // Ortadaki buton (Create) için özel işlem
    if (index == 2) {
      _showCreateBottomSheet();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index > 2 ? index - 1 : index, // Create butonu sayfa değil
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Oluştur bottom sheet
  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateSheet(),
    );
  }

  /// Mevcut kullanıcı ID'sini al
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.arkaplanKoyu,
      extendBody: true, // Bottom bar arkasında içerik görünsün
      // Sayfa içeriği
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Manuel kontrol
        children: [
          const HomeView(), // 0: Anasayfa
          const SearchScreen(), // 1: Keşfet
          // Create butonu sayfa değil, atla
          const ConversationsScreen(), // 2: Mesajlar
          ProfileScreen(userId: _currentUserId ?? ''), // 3: Profil
        ],
      ),

      // Glassmorphism Bottom Navigation
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  /// Glassmorphism Bottom Navigation Bar
  Widget _buildGlassBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
                _buildNavItem(1, Icons.explore_rounded, 'Keşfet'),
                _buildCreateButton(), // Ortadaki gradient buton
                _buildNavItem(3, Icons.chat_bubble_rounded, 'Mesajlar'),
                _buildNavItem(4, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Normal nav item
  Widget _buildNavItem(int index, IconData icon, String label) {
    // Create butonundan sonraki indeksler için düzeltme
    final isSelected =
        _selectedIndex == index || (_selectedIndex == index - 1 && index > 2);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon - Seçiliyse gradient
            if (isSelected)
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.anaGradient.createShader(bounds),
                child: Icon(icon, color: Colors.white, size: 26),
              )
            else
              Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 24),
            const SizedBox(height: 4),
            // Etiket
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ortadaki Create butonu - Gradient
  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppTheme.anaGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.morVurgu.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  /// Create Bottom Sheet içeriği
  Widget _buildCreateSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.yuzeyRengi,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst çizgi
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Başlık
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.anaGradient.createShader(bounds),
            child: const Text(
              'Oluştur',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Seçenekler
          _buildCreateOption(
            icon: Icons.photo_camera_rounded,
            title: 'Hikaye Paylaş',
            subtitle: 'Anlık fotoğraf veya video',
            onTap: () {
              Navigator.pop(context);
              // TODO: Hikaye paylaş
            },
          ),
          const SizedBox(height: 12),
          _buildCreateOption(
            icon: Icons.article_rounded,
            title: 'Gönderi Paylaş',
            subtitle: 'Fotoğraf, video veya yazı',
            onTap: () {
              Navigator.pop(context);
              // TODO: Gönderi paylaş
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Create seçenek kartı
  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              // Gradient ikon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.anaGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Metin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Ok ikonu
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
