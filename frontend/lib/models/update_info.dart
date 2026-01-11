/// Uygulama Güncellemesi Modeli
class UpdateInfo {
  final String versionNumber;
  final String apkUrl;
  final bool forceUpdate;
  final String updateMessage;

  UpdateInfo({
    required this.versionNumber,
    required this.apkUrl,
    required this.forceUpdate,
    required this.updateMessage,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionNumber: json['version_number'] ?? '0.0.0',
      apkUrl: json['apk_url'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      updateMessage: json['update_message'] ?? 'Yeni güncelleme mevcut',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version_number': versionNumber,
      'apk_url': apkUrl,
      'force_update': forceUpdate,
      'update_message': updateMessage,
    };
  }
}
