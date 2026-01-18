import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../screens/admin_panel_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GELİŞTİRİCİ AYARLARI EKRANI
/// ═══════════════════════════════════════════════════════════════════════════
///
/// API Endpoint, Cache temizleme ve Admin Panel erişimi

class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final cacheState = ref.watch(cacheNotifierProvider);
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: AppTheme.arkaplanKoyu,
      appBar: AppBar(
        title: const Text('Geliştirici Ayarları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════════════════════════════════════════════════════════════
          // API BİLGİLERİ
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('API Bilgileri'),
          const SizedBox(height: 12),

          // Supabase Endpoint
          _buildInfoCard(
            icon: Icons.cloud_outlined,
            title: 'Supabase URL',
            value: ApiConfig.supabaseUrl,
            copyable: true,
          ),
          const SizedBox(height: 8),

          // Weather API
          _buildInfoCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Weather API',
            value: ApiConfig.weatherApi,
            copyable: true,
          ),
          const SizedBox(height: 8),

          // News API
          _buildInfoCard(
            icon: Icons.newspaper_outlined,
            title: 'News API',
            value: ApiConfig.newsApi,
            copyable: true,
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // CACHE YÖNETİMİ
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Önbellek'),
          const SizedBox(height: 12),

          _buildActionButton(
            icon: Icons.cleaning_services_outlined,
            title: 'Önbelleği Temizle',
            subtitle: 'Uygulama önbelleğini temizler',
            isLoading: cacheState.isClearing,
            onTap: () async {
              await ref.read(cacheNotifierProvider.notifier).clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(cacheState.message ?? 'Önbellek temizlendi!'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // DEBUG LOG AYARI
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Geliştirici'),
          const SizedBox(height: 12),

          _buildSwitchTile(
            context: context,
            ref: ref,
            icon: Icons.bug_report_outlined,
            title: 'Debug Log',
            subtitle: 'Konsol çıktılarını göster',
            value: ref.watch(debugLogProvider),
            onChanged: (val) {
              ref.read(debugLogProvider.notifier).state = val;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val ? 'Debug log açıldı 🐛' : 'Debug log kapatıldı',
                  ),
                  backgroundColor: val
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // ADMİN PANELİ (Sadece adminler görsün)
          // ═══════════════════════════════════════════════════════════════
          isAdmin.when(
            data: (isAdminUser) {
              if (!isAdminUser) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Yönetim'),
                  const SizedBox(height: 12),

                  _buildActionButton(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Paneli',
                    subtitle: 'Kullanıcı ve içerik yönetimi',
                    isAdmin: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPanelScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // VERSİYON BİLGİSİ
          // ═══════════════════════════════════════════════════════════════
          _buildSectionTitle('Uygulama Bilgisi'),
          const SizedBox(height: 12),

          appVersion.when(
            data: (version) => _buildVersionCard(version),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Versiyon bilgisi alınamadı'),
          ),

          const SizedBox(height: 40),
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

  /// Bilgi kartı (API endpoint vb.)
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool copyable = false,
  }) {
    return Container(
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (copyable)
            Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.copy,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () {
                  // Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Kopyalandı!')));
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Aksiyon butonu
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isAdmin = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAdmin
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAdmin
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isAdmin ? null : AppTheme.anaGradient,
                  color: isAdmin ? Colors.orange : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 22),
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

  /// Versiyon kartı
  Widget _buildVersionCard(AppVersion version) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.morVurgu.withValues(alpha: 0.2),
            AppTheme.turuncuVurgu.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // App Logo
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.anaGradient.createShader(bounds),
            child: const Icon(Icons.apps, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // App Name
          Text(
            version.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              version.formatted,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Package Name
          Text(
            version.packageName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Switch tile - Toggle ayarları için
  Widget _buildSwitchTile({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
              color: value
                  ? AppTheme.morVurgu.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.morVurgu : Colors.grey,
              size: 22,
            ),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.morVurgu,
            activeTrackColor: AppTheme.morVurgu.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
