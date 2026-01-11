import 'package:flutter/material.dart';
import 'package:r_upgrade/r_upgrade.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

/// OTA Güncelleme Dialog'u
///
/// Özellikleri:
/// - Modern, şık tasarım
/// - Progress göstergesi
/// - Zorunlu/Opsiyonel güncelleme desteği
/// - APK indirme ve kurulum
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();

  /// Static helper - Dialog'u göster
  static Future<void> show(BuildContext context, UpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible:
          !updateInfo.forceUpdate, // Zorunlu güncelleme kapatılamaz
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'İndiriliyor...';
    });

    try {
      print('📥 APK indirme başlıyor: ${widget.updateInfo.apkUrl}');

      // r_upgrade ile APK indir ve kur
      await RUpgrade.upgrade(
        widget.updateInfo.apkUrl,
        fileName: 'app-update.apk',
        installType: RUpgradeInstallType.normal,
        useDownloadManager: false,
      );

      print('✅ Güncelleme başlatıldı');

      if (mounted) {
        setState(() {
          _statusMessage = 'Kurulum başlatılıyor...';
        });
      }
    } catch (e, stackTrace) {
      print('❌ Güncelleme hatası: $e');
      print('Stack: $stackTrace');

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVersion = '0.0.0'; // Bu dinamik olarak alınabilir
    final updateType = _updateService.getUpdateTypeDescription(
      widget.updateInfo.versionNumber,
      currentVersion,
    );

    return WillPopScope(
      onWillPop: () async => !widget
          .updateInfo
          .forceUpdate, // Zorunlu güncelleme geri tuşunu engeller
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (Gradient)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.system_update,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Yeni Güncelleme Mevcut!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _updateService.formatVersion(
                        widget.updateInfo.versionNumber,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.updateInfo.forceUpdate
                            ? Colors.red[400]
                            : Colors.green[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.updateInfo.forceUpdate
                            ? 'Zorunlu Güncelleme'
                            : updateType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Update Message
                    Text(
                      widget.updateInfo.updateMessage,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Progress Bar (İndirme sırasında)
                    if (_isDownloading) ...[
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress > 0
                                ? _downloadProgress / 100
                                : null,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF667eea),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_downloadProgress > 0)
                                Text(
                                  '${_downloadProgress.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Buttons
              if (!_isDownloading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Sonra butonu (sadece opsiyonel güncellemelerde)
                      if (!widget.updateInfo.forceUpdate)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Sonra',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),

                      if (!widget.updateInfo.forceUpdate)
                        const SizedBox(width: 12),

                      // Şimdi Güncelle butonu
                      Expanded(
                        flex: widget.updateInfo.forceUpdate ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _startUpdate,
                          style:
                              ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                  const Color(0xFF667eea),
                                ),
                              ),
                          child: const Text(
                            'Şimdi Güncelle',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
