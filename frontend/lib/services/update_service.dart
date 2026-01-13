import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Update Info Model - Güncelleme bilgileri
class AppUpdateInfo {
  final String currentVersion;
  final int buildNumber;
  final String downloadUrl;
  final bool isForceUpdate;
  final String releaseNotes;

  AppUpdateInfo({
    required this.currentVersion,
    required this.buildNumber,
    required this.downloadUrl,
    required this.isForceUpdate,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      currentVersion: json['current_version'] ?? '1.0.0',
      buildNumber: json['build_number'] ?? 1,
      downloadUrl: json['download_url'] ?? '',
      isForceUpdate: json['is_force_update'] ?? false,
      releaseNotes: json['release_notes'] ?? '',
    );
  }
}

/// Gelişmiş Güncelleme Servisi
///
/// Özellikler:
/// - Build number karşılaştırması
/// - Zorunlu güncelleme desteği
/// - Release notes
/// - Realtime listener
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription? _realtimeSubscription;
  int? _currentBuildNumber;
  BuildContext? _context;
  bool _dialogShowing = false;

  /// Servisi başlat ve context'i kaydet
  Future<void> init(BuildContext context) async {
    _context = context;

    // Yerel build number'ı al
    final packageInfo = await PackageInfo.fromPlatform();
    _currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

    print('📱 Uygulama Build: $_currentBuildNumber');

    // İlk kontrol
    await checkForUpdate();

    // Realtime listener başlat
    _startRealtimeListener();
  }

  /// Servisi kapat
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  /// Güncelleme kontrolü yap (10 saniye timeout)
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      // 10 saniye timeout ile sorgu
      final response = await _supabase
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ Güncelleme kontrolü timeout (10s)');
              return null;
            },
          );

      if (response == null) {
        print('⚠️ app_config tablosunda kayıt yok veya timeout');
        return null;
      }

      final updateInfo = AppUpdateInfo.fromJson(response);

      print('🌐 Sunucu Build: ${updateInfo.buildNumber}');
      print('📱 Yerel Build: $_currentBuildNumber');

      // Build number karşılaştır
      if (_currentBuildNumber != null &&
          updateInfo.buildNumber > _currentBuildNumber!) {
        print(
          '✅ Güncelleme mevcut: Build $_currentBuildNumber → ${updateInfo.buildNumber}',
        );
        _showUpdateDialog(updateInfo);
        return updateInfo;
      } else {
        print('ℹ️ Uygulama güncel (Build $_currentBuildNumber)');
        return null;
      }
    } catch (e) {
      print('❌ Güncelleme kontrolü hatası: $e');
      return null;
    }
  }

  /// Realtime listener - Tablo değiştiğinde otomatik kontrol
  void _startRealtimeListener() {
    _realtimeSubscription = _supabase
        .from('app_config')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (data.isNotEmpty) {
            final updateInfo = AppUpdateInfo.fromJson(data.first);

            if (_currentBuildNumber != null &&
                updateInfo.buildNumber > _currentBuildNumber!) {
              print('🔔 Realtime: Yeni güncelleme algılandı!');
              _showUpdateDialog(updateInfo);
            }
          }
        });

    print('👂 Realtime listener başlatıldı');
  }

  /// Güncelleme dialogunu göster
  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    if (_context == null || !_context!.mounted || _dialogShowing) return;

    _dialogShowing = true;

    showDialog(
      context: _context!,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => AppUpdateDialog(updateInfo: updateInfo),
    ).then((_) => _dialogShowing = false);
  }
}

/// Modern Güncelleme Dialogu
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  Future<void> _launchUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(updateInfo.downloadUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı açılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.isForceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: updateInfo.isForceUpdate
                      ? [Colors.red.shade400, Colors.orange.shade400]
                      : [Colors.blue.shade400, Colors.purple.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yeni Güncelleme Mevcut!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'v${updateInfo.currentVersion}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (updateInfo.isForceUpdate)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bu güncelleme zorunludur. Devam etmek için güncelleme yapmalısınız.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const Text(
                'Yenilikler:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (!updateInfo.isForceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Daha Sonra',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => _launchUrl(context),
            icon: const Icon(Icons.download),
            label: const Text(
              'Güncelle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: updateInfo.isForceUpdate
                  ? Colors.red
                  : Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
