import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/supabase_service.dart';
import 'developer_settings_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SETTINGS VIEW - Modern Ayarlar Ekranı (Riverpod)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Gruplandırılmış ayarlar listesi:
/// - Hesap: Profil, Şifre
/// - Tercihler: Bildirimler, Gizlilik
/// - Sistem: API, Yardım, Çıkış

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final appVersion = ref.watch(appVersionProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.arkaplanKoyu,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════════════════════════════════════════════════════════════
          // KULLANICI BAŞLIĞI
          // ═══════════════════════════════════════════════════════════════
          _buildUserHeader(currentUser),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // HESAP BÖLÜMÜ
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Hesap'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Profili Düzenle',
            subtitle: 'Ad, soyad, hakkında',
            onTap: () => _showEditProfileDialog(context),
          ),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            subtitle: 'Güvenlik ayarları',
            onTap: () => _showChangePasswordDialog(context),
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // TERCİHLER BÖLÜMÜ
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Tercihler'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            subtitle: 'Push bildirim ayarları',
            onTap: () => _showNotificationSettings(context),
          ),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik',
            subtitle: 'Profil görünürlüğü',
            onTap: () => _showPrivacySettings(context),
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // SİSTEM BÖLÜMÜ
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Sistem'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            icon: Icons.code,
            title: 'Geliştirici Ayarları',
            subtitle: 'API ve önbellek',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeveloperSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Yardım & Destek',
            subtitle: 'S.S.S. ve iletişim',
            onTap: () => _showHelpDialog(context),
          ),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: appVersion.when(
              data: (v) => v.formatted,
              loading: () => 'Yükleniyor...',
              error: (_, __) => 'v1.0.0',
            ),
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // TEHLİKELİ BÖLGE
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Tehlikeli Bölge'),
          const SizedBox(height: 12),

          // Çıkış Yap
          _buildDangerButton(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            onTap: () => _logout(context),
            isDestructive: false,
          ),
          const SizedBox(height: 8),

          // Hesabı Sil
          _buildDangerButton(
            icon: Icons.delete_forever,
            title: 'Hesabımı Sil',
            onTap: () => _deleteAccount(context),
            isDestructive: true,
          ),

          const SizedBox(height: 40),

          // ═══════════════════════════════════════════════════════════════
          // VERSİYON BİLGİSİ (Alt)
          // ═══════════════════════════════════════════════════════════════
          Center(
            child: appVersion.when(
              data: (v) => Text(
                'Vibe ${v.formatted}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Kullanıcı başlığı
  Widget _buildUserHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.morVurgu.withValues(alpha: 0.3),
            AppTheme.turuncuVurgu.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.anaGradient,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email?.split('@').first ?? 'Kullanıcı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bölüm başlığı
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Ayar satırı
  Widget _buildSettingsTile({
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.morVurgu.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.morVurgu, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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

  /// Tehlikeli buton
  Widget _buildDangerButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOG FONKSİYONLARI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Profil düzenleme
  Future<void> _showEditProfileDialog(BuildContext context) async {
    final supabaseService = SupabaseService();
    final currentUser = await supabaseService.getCurrentUser();

    final firstNameController = TextEditingController(
      text: currentUser?['first_name'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: currentUser?['last_name'] ?? '',
    );
    final bioController = TextEditingController(
      text: currentUser?['bio'] ?? '',
    );

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.yuzeyRengi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              firstNameController,
              'Ad',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildDialogTextField(
              lastNameController,
              'Soyad',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildDialogTextField(
              bioController,
              'Hakkında',
              Icons.info_outline,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.morVurgu,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await supabaseService.updateProfile(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          bio: bioController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil güncellendi! ✅'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Şifre değiştirme
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.yuzeyRengi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Şifre Değiştir',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              emailController,
              'E-posta',
              Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.morVurgu,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty && context.mounted) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          emailController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Şifre sıfırlama bağlantısı gönderildi! ✅'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Bildirim ayarları
  void _showNotificationSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim ayarları yakında eklenecek!')),
    );
  }

  /// Gizlilik ayarları
  void _showPrivacySettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gizlilik ayarları yakında eklenecek!')),
    );
  }

  /// Yardım dialog
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.yuzeyRengi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Yardım & Destek',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              Icons.email_outlined,
              'E-posta',
              'destek@vibeapp.com',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(Icons.language, 'Web', 'www.vibeapp.com'),
            const SizedBox(height: 12),
            _buildHelpItem(
              Icons.article_outlined,
              'S.S.S.',
              'Sıkça sorulan sorular',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Hakkında dialog
  void _showAboutDialog(BuildContext context) {
    final appVersion = ref.read(appVersionProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.yuzeyRengi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.anaGradient.createShader(bounds),
              child: const Icon(
                Icons.people_alt_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vibe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            appVersion.when(
              data: (v) => Text(
                v.formatted,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('v1.0.0'),
            ),
            const SizedBox(height: 16),
            Text(
              'Yeni arkadaşlar edin, bağlantılar kur.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Yardım satırı
  Widget _buildHelpItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.morVurgu, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  /// Dialog text field
  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Çıkış yap
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.yuzeyRengi,
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  /// Hesabı sil
  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.yuzeyRengi,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Hesabı Sil', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Bu işlem GERİ ALINAMAZ!\n\nTüm verileriniz silinecek.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final supabaseService = SupabaseService();
        final userId = supabaseService.client.auth.currentUser?.id;

        if (userId != null) {
          await supabaseService.client
              .from('messages')
              .delete()
              .or('sender_id.eq.$userId,receiver_id.eq.$userId');
          await supabaseService.client
              .from('friendships')
              .delete()
              .or('user_id_1.eq.$userId,user_id_2.eq.$userId');
          await supabaseService.client.from('users').delete().eq('id', userId);
          await supabaseService.client.auth.signOut();
        }

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
