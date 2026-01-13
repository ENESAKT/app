import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

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
      currentVersion: (json['current_version'] ?? '1.0.0').toString().trim(),
      buildNumber: json['build_number'] ?? 1,
      downloadUrl: (json['download_url'] ?? '').toString().trim(),
      isForceUpdate: json['is_force_update'] ?? false,
      releaseNotes: (json['release_notes'] ?? '').toString().trim(),
    );
  }
}

/// Gelişmiş Güncelleme Servisi - In-App Download destekli
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();

  StreamSubscription? _realtimeSubscription;
  int? _currentBuildNumber;
  BuildContext? _context;
  bool _dialogShowing = false;

  /// Servisi başlat
  Future<void> init(BuildContext context) async {
    _context = context;

    final packageInfo = await PackageInfo.fromPlatform();
    _currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

    print('📱 Uygulama Build: $_currentBuildNumber');

    await checkForUpdate();
    _startRealtimeListener();
  }

  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  /// Güncelleme kontrolü (10s timeout)
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      if (response == null) {
        print('⚠️ app_config yok veya timeout');
        return null;
      }

      final updateInfo = AppUpdateInfo.fromJson(response);

      print('🌐 Sunucu Build: ${updateInfo.buildNumber}');
      print('📱 Yerel Build: $_currentBuildNumber');

      if (_currentBuildNumber != null &&
          updateInfo.buildNumber > _currentBuildNumber!) {
        print('✅ Güncelleme mevcut!');
        _showUpdateDialog(updateInfo);
        return updateInfo;
      } else {
        print('ℹ️ Uygulama güncel');
        return null;
      }
    } catch (e) {
      print('❌ Güncelleme kontrolü hatası: $e');
      return null;
    }
  }

  void _startRealtimeListener() {
    _realtimeSubscription = _supabase
        .from('app_config')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (data.isNotEmpty) {
            final updateInfo = AppUpdateInfo.fromJson(data.first);
            if (_currentBuildNumber != null &&
                updateInfo.buildNumber > _currentBuildNumber!) {
              _showUpdateDialog(updateInfo);
            }
          }
        });
  }

  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    if (_context == null || !_context!.mounted || _dialogShowing) return;
    _dialogShowing = true;

    showDialog(
      context: _context!,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => InAppUpdateDialog(
        updateInfo: updateInfo,
        onDownload: () => downloadAndInstall(updateInfo.downloadUrl),
      ),
    ).then((_) => _dialogShowing = false);
  }

  /// 📥 APK'yı indir ve kur (In-App)
  Future<void> downloadAndInstall(String url) async {
    if (_context == null || !_context!.mounted) return;

    // Storage izni kontrolü
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar('Depolama izni gerekli!', Colors.red);
        return;
      }
    }

    // Progress dialog göster
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) =>
          DownloadProgressDialog(downloadFuture: _downloadApk(url)),
    );
  }

  Future<String?> _downloadApk(String url) async {
    try {
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/update.apk';

      print('📥 İndiriliyor: $url');
      print('📁 Kayıt: $filePath');

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('⬇️ İndirme: $progress%');
          }
        },
      );

      print('✅ İndirme tamamlandı, kurulum başlatılıyor...');

      // Kurulum ekranını aç
      final result = await OpenFilex.open(filePath);
      print('📦 Kurulum sonucu: ${result.message}');

      return filePath;
    } catch (e) {
      print('❌ İndirme hatası: $e');
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pop();
        _showSnackBar('İndirme başarısız: $e', Colors.red);
      }
      return null;
    }
  }

  void _showSnackBar(String message, Color color) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(
        _context!,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }
}

/// In-App Güncelleme Dialogu
class InAppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onDownload;

  const InAppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDownload,
  });

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
                      : [Colors.deepPurple.shade400, Colors.purple.shade400],
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
                    'Yeni Güncelleme!',
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
                        'Bu güncelleme zorunludur!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const Text(
                'Yenilikler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!updateInfo.isForceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sonra'),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDownload();
            },
            icon: const Icon(Icons.download),
            label: const Text('İndir & Kur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
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

/// İndirme Progress Dialogu
class DownloadProgressDialog extends StatefulWidget {
  final Future<String?> downloadFuture;

  const DownloadProgressDialog({super.key, required this.downloadFuture});

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  @override
  void initState() {
    super.initState();
    widget.downloadFuture.then((path) {
      if (mounted && path != null) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 20),
          const Text(
            'Güncelleme indiriliyor...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bekleyin',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
