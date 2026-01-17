import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_provider.dart';
import '../services/update_service.dart';
import '../services/supabase_service.dart';

/// Ayarlar ekranı - Profil ve uygulama ayarları
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Dinamik versiyon bilgisi
  String _version = '...';
  String _buildNumber = '...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      print('📱 Versiyon bilgisi yükleniyor...');
      final packageInfo = await PackageInfo.fromPlatform();
      print(
        '📱 PackageInfo alındı: ${packageInfo.version} (${packageInfo.buildNumber})',
      );

      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
        print('✅ Versiyon güncellendi: v$_version (Build $_buildNumber)');
      }
    } catch (e) {
      print('❌ Versiyon bilgisi alınamadı: $e');
      if (mounted) {
        setState(() {
          _version = 'Hata';
          _buildNumber = '-';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Profil Bölümü
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user?.profilePhoto != null
                      ? NetworkImage(user!.profilePhoto!)
                      : null,
                  child: user?.profilePhoto == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Güncelleme Bölümü
          _buildSection(
            title: 'Uygulama',
            children: [
              _buildListTile(
                icon: Icons.update,
                title: 'Güncellemeleri Kontrol Et',
                subtitle: 'En son sürümü indirin',
                onTap: () => _checkForUpdates(context),
                trailing: const Icon(Icons.open_in_new, size: 20),
              ),
              _buildListTile(
                icon: Icons.info_outline,
                title: 'Sürüm',
                subtitle:
                    'v$_version (Build $_buildNumber)', // DİNAMİK VERSİYON
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hesap Bölümü
          _buildSection(
            title: 'Hesap',
            children: [
              _buildListTile(
                icon: Icons.person_outline,
                title: 'Profili Düzenle',
                subtitle: 'Bilgilerinizi güncelleyin',
                onTap: () => _showEditProfileDialog(context),
              ),
              _buildListTile(
                icon: Icons.lock_outline,
                title: 'Şifreyi Değiştir',
                subtitle: 'Güvenliğinizi koruyun',
                onTap: () {
                  // TODO: Şifre değiştirme
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Diğer
          _buildSection(
            title: 'Diğer',
            children: [
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Yardım & Destek',
                subtitle: 'S.S.S ve destek',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Hesabımı Sil Butonu (Kritik)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _deleteAccount(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'Hesabımı Sil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Çıkış Yap Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF667eea)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  /// Profil düzenleme dialogu - Ad Soyad ve Bio
  Future<void> _showEditProfileDialog(BuildContext context) async {
    final supabaseService = SupabaseService();

    // Mevcut kullanıcı verilerini yükle
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
        title: const Text('Profili Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Hakkında',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        // Profili güncelle
        await supabaseService.updateProfile(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          bio: bioController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil güncellendi! ✅'),
              backgroundColor: Colors.green,
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

    // Controller'ları temizle
    firstNameController.dispose();
    lastNameController.dispose();
    bioController.dispose();
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    print('🔍 Ayarlar ekranından güncelleme kontrolü başlatılıyor...');

    // Loading indicator göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Güncellemeler kontrol ediliyor...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // UpdateService'i kullanarak güncelleme kontrolü yap (manual: true)
    // Bu, güncelleme varsa dialog gösterecek, yoksa SnackBar gösterecek
    await UpdateService().checkForUpdate(context: context, manual: true);
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider).signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// Hesabı Sil - Kritik işlem, çift onay gerektirir
  Future<void> _deleteAccount(BuildContext context) async {
    // İlk onay
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Hesabı Sil'),
          ],
        ),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz?\n\n'
          '⚠️ Bu işlem GERİ ALINAMAZ!\n'
          '• Tüm verileriniz silinecek\n'
          '• Mesajlarınız silinecek\n'
          '• Arkadaşlık bağlantılarınız kaldırılacak',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Evet, Silmek İstiyorum'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !context.mounted) return;

    // İkinci onay - "SİL" yazmasını iste
    final deleteController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Son Onay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Onaylamak için aşağıya "SİL" yazın:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deleteController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'SİL',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (deleteController.text.trim().toUpperCase() == 'SİL') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen "SİL" yazın'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hesabımı Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !context.mounted) return;

    // Hesabı sil
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final supabaseService = SupabaseService();
      final userId = supabaseService.client.auth.currentUser?.id;

      if (userId != null) {
        // Kullanıcı verilerini sil (messages, friendships, users tablosu)
        await supabaseService.client
            .from('messages')
            .delete()
            .or('sender_id.eq.$userId,receiver_id.eq.$userId');

        await supabaseService.client
            .from('friendships')
            .delete()
            .or('user_id_1.eq.$userId,user_id_2.eq.$userId');

        await supabaseService.client.from('users').delete().eq('id', userId);

        // Auth hesabını sil (Supabase Admin API gerektirir - RPC ile)
        // Not: Supabase client tarafından auth.admin.deleteUser() kullanılamaz
        // Bu nedenle sadece oturumu kapatıyoruz, tam silme için backend gerekli
        await supabaseService.client.auth.signOut();
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Loading'i kapat

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Hesabınız silindi. Hoşçakalın!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Loading'i kapat

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
