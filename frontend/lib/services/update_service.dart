import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UPDATE INFO MODEL
/// ═══════════════════════════════════════════════════════════════════════════

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

/// ═══════════════════════════════════════════════════════════════════════════
/// DOWNLOAD PROGRESS MODEL
/// ═══════════════════════════════════════════════════════════════════════════

class DownloadProgress {
  final int received;
  final int total;
  final double percentage;
  final DownloadStatus status;
  final String? error;

  DownloadProgress({
    this.received = 0,
    this.total = 0,
    this.percentage = 0,
    this.status = DownloadStatus.idle,
    this.error,
  });

  DownloadProgress copyWith({
    int? received,
    int? total,
    double? percentage,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadProgress(
      received: received ?? this.received,
      total: total ?? this.total,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

enum DownloadStatus { idle, downloading, completed, error }

/// ═══════════════════════════════════════════════════════════════════════════
/// UPDATE SERVICE - Singleton
/// ═══════════════════════════════════════════════════════════════════════════

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();

  StreamSubscription? _realtimeSubscription;
  String? _currentVersion; // Semantic version (e.g., "1.0.22")
  int? _currentBuildNumber;
  BuildContext? _context;
  bool _dialogShowing = false;

  /// Progress notifier - UI bunu dinleyecek
  final ValueNotifier<DownloadProgress> progressNotifier = ValueNotifier(
    DownloadProgress(),
  );

  /// ════════════════════════════════════════════════════════════════════════
  /// INIT - Servisi başlat
  /// ════════════════════════════════════════════════════════════════════════

  Future<void> init(BuildContext context) async {
    print('');
    print('🚀 UPDATE SERVICE BAŞLATILIYOR...');

    _context = context;

    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version.trim(); // e.g., "1.0.22"
    _currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

    print('📱 App: ${packageInfo.appName}');
    print('📱 Version: $_currentVersion');
    print('📱 Build: $_currentBuildNumber');

    await checkForUpdate();
    _startRealtimeListener();
  }

  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    progressNotifier.dispose();
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// CHECK FOR UPDATE - Supabase'den kontrol
  /// ════════════════════════════════════════════════════════════════════════

  /// Manuel kontrol için: checkForUpdate(context: ctx, manual: true)
  /// Otomatik kontrol için: checkForUpdate() veya checkForUpdate(manual: false)
  Future<AppUpdateInfo?> checkForUpdate({
    BuildContext? context,
    bool manual = false,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔍 UPDATE KONTROLÜ ${manual ? "(MANUEL)" : "(OTOMATİK)"}');
    print('═══════════════════════════════════════════════════════');

    // Manuel çağrılarda context güncelle
    if (context != null) {
      _context = context;
    }

    // Eğer _currentVersion henüz set edilmemişse, şimdi al
    if (_currentVersion == null) {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version.trim();
      _currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
      print('📱 Yerel Version alındı: $_currentVersion');
    }

    try {
      final response = await _supabase
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      if (response == null) {
        print('❌ app_config tablosunda veri yok!');
        if (manual) {
          _showSnackBar('Güncelleme bilgisi alınamadı.', Colors.orange);
        }
        return null;
      }

      print('📦 Supabase Response: $response');

      final updateInfo = AppUpdateInfo.fromJson(response);
      final remoteVersion = updateInfo.currentVersion.trim();
      final localVersion = _currentVersion!.trim();

      print('📊 Sunucu Version: "$remoteVersion"');
      print('📱 Yerel Version: "$localVersion"');

      // Semantic version karşılaştırması
      final comparison = _compareVersions(remoteVersion, localVersion);
      print(
        '🔍 Karşılaştırma: $comparison (1=güncelleme var, 0=eşit, -1=yerel daha yeni)',
      );

      // SADECE remoteVersion > localVersion ise güncelleme göster
      // Eşit (comparison == 0) durumda ASLA güncelleme diyaloğu gösterme
      if (comparison > 0) {
        print('✅ GÜNCELLEME MEVCUT! ($remoteVersion > $localVersion)');
        _showUpdateDialog(updateInfo);
        return updateInfo;
      } else {
        // comparison <= 0: Eşit veya yerel daha yeni - güncelleme yok
        print(
          'ℹ️ Uygulama güncel. (Remote: $remoteVersion, Local: $localVersion, Comparison: $comparison)',
        );
        if (manual) {
          _showSnackBar('✅ Uygulamanız güncel!', Colors.green);
        }
        return null;
      }
    } catch (e) {
      print('❌ Hata: $e');
      if (manual) {
        _showSnackBar('Güncelleme kontrolü başarısız: $e', Colors.red);
      }
      return null;
    }
  }

  /// Semantic version karşılaştırması: "1.0.22" vs "1.0.21"
  /// Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
  int _compareVersions(String v1, String v2) {
    final parts1 = _parseVersion(v1);
    final parts2 = _parseVersion(v2);

    // Major karşılaştır
    if (parts1[0] != parts2[0]) {
      return parts1[0] > parts2[0] ? 1 : -1;
    }
    // Minor karşılaştır
    if (parts1[1] != parts2[1]) {
      return parts1[1] > parts2[1] ? 1 : -1;
    }
    // Patch karşılaştır
    if (parts1[2] != parts2[2]) {
      return parts1[2] > parts2[2] ? 1 : -1;
    }
    return 0; // Eşit
  }

  /// Version string'i parse et: "1.0.22" -> [1, 0, 22]
  List<int> _parseVersion(String version) {
    final cleanVersion = version.split('+').first; // "1.0.22+1" -> "1.0.22"
    final parts = cleanVersion.split('.');
    return [
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// REALTIME LISTENER
  /// ════════════════════════════════════════════════════════════════════════

  void _startRealtimeListener() {
    _realtimeSubscription = _supabase
        .from('app_config')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (data.isNotEmpty && _currentVersion != null) {
            final updateInfo = AppUpdateInfo.fromJson(data.first);
            final remoteVersion = updateInfo.currentVersion.trim();
            final localVersion = _currentVersion!.trim();
            final comparison = _compareVersions(remoteVersion, localVersion);

            // SADECE remoteVersion > localVersion ise güncelleme göster
            if (comparison > 0 && !_dialogShowing) {
              print(
                '🔔 Realtime: Yeni güncelleme tespit edildi! $remoteVersion > $localVersion',
              );
              _showUpdateDialog(updateInfo);
            }
          }
        });
    print('👂 Realtime listener aktif.');
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// SHOW UPDATE DIALOG
  /// ════════════════════════════════════════════════════════════════════════

  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    if (_context == null || !_context!.mounted || _dialogShowing) return;
    _dialogShowing = true;

    showDialog(
      context: _context!,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => UpdateAvailableDialog(
        updateInfo: updateInfo,
        onDownload: () => downloadAndInstall(updateInfo.downloadUrl),
      ),
    ).then((_) => _dialogShowing = false);
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// DOWNLOAD AND INSTALL - ANA FONKSİYON
  /// ════════════════════════════════════════════════════════════════════════

  Future<void> downloadAndInstall(String url) async {
    if (_context == null || !_context!.mounted) return;

    print('');
    print('═══════════════════════════════════════════════════════');
    print('📥 İNDİRME BAŞLIYOR');
    print('═══════════════════════════════════════════════════════');
    print('🔗 URL: $url');

    // 1. İzin kontrolü
    if (Platform.isAndroid) {
      final installPermission = await Permission.requestInstallPackages
          .request();
      if (!installPermission.isGranted) {
        _showSnackBar(
          'Bilinmeyen kaynaklardan yükleme izni gerekli!',
          Colors.red,
        );
        return;
      }
      print('✅ Install permission granted');
    }

    // 2. Progress dialogu göster
    progressNotifier.value = DownloadProgress(
      status: DownloadStatus.downloading,
    );

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) =>
          DownloadProgressDialog(progressNotifier: progressNotifier),
    );

    // 3. İndirme işlemini başlat
    try {
      final filePath = await _downloadApk(url);

      if (filePath != null && _context!.mounted) {
        Navigator.of(_context!).pop(); // Dialog kapat

        // 4. APK kurulumunu başlat
        print('📦 Kurulum başlatılıyor: $filePath');
        final result = await OpenFilex.open(filePath);
        print('📦 Sonuç: ${result.message}');
      }
    } catch (e) {
      print('❌ İndirme hatası: $e');
      progressNotifier.value = DownloadProgress(
        status: DownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// DOWNLOAD APK - Dio ile indirme
  /// ════════════════════════════════════════════════════════════════════════

  Future<String?> _downloadApk(String url) async {
    try {
      // ═══════════════════════════════════════════════════════════════════════
      // KRİTİK: APK'yı EXTERNAL storage'a kaydet!
      // Internal storage (getApplicationDocumentsDirectory) kullanılırsa
      // Android Package Installer dosyaya erişemez ve "Uygulama yüklenemedi" hatası verir.
      // ═══════════════════════════════════════════════════════════════════════

      Directory? dir;

      // Önce external storage dene
      if (Platform.isAndroid) {
        // External cache directories dene (daha güvenli)
        final externalCacheDirs = await getExternalCacheDirectories();
        if (externalCacheDirs != null && externalCacheDirs.isNotEmpty) {
          dir = externalCacheDirs.first;
          print('📁 External cache kullanılıyor: ${dir.path}');
        } else {
          // Fallback: External storage directory
          dir = await getExternalStorageDirectory();
          print('📁 External storage kullanılıyor: ${dir?.path}');
        }
      }

      // Eğer hala null ise, son çare olarak documents kullan (ama bu çalışmayabilir)
      dir ??= await getApplicationDocumentsDirectory();

      final filePath = '${dir.path}/update.apk';

      // Eski dosyayı sil
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Eski APK silindi');
      }

      print('📁 Kayıt yeri: $filePath');

      // İndirme başlat
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percentage = (received / total) * 100;
            progressNotifier.value = DownloadProgress(
              received: received,
              total: total,
              percentage: percentage,
              status: DownloadStatus.downloading,
            );

            // Her %10'da bir log
            if (percentage.toInt() % 10 == 0) {
              print('⬇️ İndirme: ${percentage.toStringAsFixed(0)}%');
            }
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      // Tamamlandı
      progressNotifier.value = DownloadProgress(
        percentage: 100,
        status: DownloadStatus.completed,
      );

      print('✅ İndirme tamamlandı!');
      return filePath;
    } catch (e) {
      print('❌ Download error: $e');
      progressNotifier.value = DownloadProgress(
        status: DownloadStatus.error,
        error: e.toString(),
      );

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

/// ═══════════════════════════════════════════════════════════════════════════
/// UPDATE AVAILABLE DIALOG - Güncelleme bildirimi
/// ═══════════════════════════════════════════════════════════════════════════

class UpdateAvailableDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onDownload;

  const UpdateAvailableDialog({
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
              padding: const EdgeInsets.all(12),
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
                constraints: const BoxConstraints(maxHeight: 100),
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

/// ═══════════════════════════════════════════════════════════════════════════
/// DOWNLOAD PROGRESS DIALOG - Yüzde gösterimli indirme ekranı
/// ═══════════════════════════════════════════════════════════════════════════

class DownloadProgressDialog extends StatelessWidget {
  final ValueNotifier<DownloadProgress> progressNotifier;

  const DownloadProgressDialog({super.key, required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Kapatılamaz
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ValueListenableBuilder<DownloadProgress>(
          valueListenable: progressNotifier,
          builder: (context, progress, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon ve başlık
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_download,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Durum metni
                Text(
                  _getStatusText(progress.status),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Yüzde metni
                Text(
                  '${progress.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.percentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Boyut bilgisi
                Text(
                  _formatBytes(progress.received, progress.total),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),

                // Hata durumu
                if (progress.status == DownloadStatus.error) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            progress.error ?? 'Bilinmeyen hata',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.idle:
        return 'Hazırlanıyor...';
      case DownloadStatus.downloading:
        return 'İndiriliyor...';
      case DownloadStatus.completed:
        return 'Tamamlandı!';
      case DownloadStatus.error:
        return 'Hata Oluştu';
    }
  }

  String _formatBytes(int received, int total) {
    if (total == 0) return 'Hesaplanıyor...';

    final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
    final totalMB = (total / 1024 / 1024).toStringAsFixed(1);

    return '$receivedMB MB / $totalMB MB';
  }
}
