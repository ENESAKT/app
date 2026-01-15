import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'update_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIREBASE NOTIFICATION SERVICE
/// Push notification'ları yönetir ve güncelleme bildirimlerini işler
/// ═══════════════════════════════════════════════════════════════════════════

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  /// ════════════════════════════════════════════════════════════════════════
  /// INITIALIZE - Servisi başlat
  /// ════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) {
      print('ℹ️ FirebaseNotificationService zaten başlatılmış.');
      return;
    }

    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔔 FIREBASE NOTIFICATION SERVICE BAŞLATILIYOR...');
    print('═══════════════════════════════════════════════════════');

    try {
      // 1. İzin iste
      await _requestPermission();

      // 2. "all" topic'ine subscribe ol
      await _subscribeToUpdatesTopic();

      // 3. Foreground mesaj dinleyicisi
      _setupForegroundMessageHandler();

      // 4. Background/Terminated mesaj dinleyicisi
      _setupBackgroundMessageHandler();

      // 5. Bildirime tıklama dinleyicisi
      _setupNotificationOpenHandler();

      // 6. FCM Token'ı logla (debug için)
      await _logFcmToken();

      _initialized = true;
      print('✅ FirebaseNotificationService başarıyla başlatıldı!');
      print('═══════════════════════════════════════════════════════');
    } catch (e) {
      print('❌ FirebaseNotificationService başlatma hatası: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// REQUEST PERMISSION - Bildirim izni iste
  /// ════════════════════════════════════════════════════════════════════════

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Bildirim izni durumu: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Bildirim izni verildi');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Geçici bildirim izni verildi');
    } else {
      print('❌ Bildirim izni reddedildi');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// SUBSCRIBE TO UPDATES TOPIC - Güncelleme topic'ine abone ol
  /// ════════════════════════════════════════════════════════════════════════

  Future<void> _subscribeToUpdatesTopic() async {
    try {
      await _messaging.subscribeToTopic('all');
      print('✅ "all" topic\'ine abone olundu');
    } catch (e) {
      print('❌ Topic subscription hatası: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// FOREGROUND MESSAGE HANDLER - Uygulama açıkken gelen mesajlar
  /// ════════════════════════════════════════════════════════════════════════

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('');
      print('📬 FOREGROUND MESAJ ALINDI:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      // Güncelleme bildirimi mi kontrol et
      if (_isUpdateNotification(message)) {
        print('🚀 Güncelleme bildirimi tespit edildi!');
        _handleUpdateNotification();
      }
    });
    print('👂 Foreground mesaj dinleyicisi aktif');
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// BACKGROUND MESSAGE HANDLER - Uygulama arka plandayken gelen mesajlar
  /// ════════════════════════════════════════════════════════════════════════

  void _setupBackgroundMessageHandler() {
    // Background handler main.dart'ta top-level function olarak tanımlanmalı
    // Bu sadece setup için
    print('👂 Background mesaj handler aktif (main.dart\'ta tanımlı)');
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// NOTIFICATION OPEN HANDLER - Bildirime tıklandığında
  /// ════════════════════════════════════════════════════════════════════════

  void _setupNotificationOpenHandler() {
    // Uygulama arka plandayken bildirime tıklandı
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('');
      print('👆 BİLDİRİME TIKLANDI (Background):');
      print('   Title: ${message.notification?.title}');
      print('   Data: ${message.data}');

      if (_isUpdateNotification(message)) {
        print('🚀 Güncelleme kontrolü tetikleniyor...');
        _handleUpdateNotification();
      }
    });

    // Uygulama tamamen kapalıyken bildirime tıklandı
    _checkInitialMessage();

    print('👂 Notification open handler aktif');
  }

  /// Uygulama kapalıyken gelen bildirim
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      print('');
      print('👆 UYGULAMA BİLDİRİMLE AÇILDI (Terminated):');
      print('   Title: ${initialMessage.notification?.title}');

      if (_isUpdateNotification(initialMessage)) {
        // Kısa bir gecikme ekle (UI hazır olsun)
        await Future.delayed(const Duration(seconds: 2));
        _handleUpdateNotification();
      }
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// HELPER METHODS
  /// ════════════════════════════════════════════════════════════════════════

  /// Güncelleme bildirimi mi kontrol et
  bool _isUpdateNotification(RemoteMessage message) {
    // Data'da "type": "app_update" varsa veya
    // title'da "güncelleme" geçiyorsa
    final type = message.data['type'];
    final title = message.notification?.title?.toLowerCase() ?? '';

    return type == 'app_update' ||
        title.contains('güncelleme') ||
        title.contains('update');
  }

  /// Güncelleme bildirimi gelince
  void _handleUpdateNotification() {
    // UpdateService'i tetikle
    UpdateService().checkForUpdate(manual: false);
  }

  /// FCM Token'ı logla
  Future<void> _logFcmToken() async {
    try {
      final token = await _messaging.getToken();
      print('🔑 FCM Token: ${token?.substring(0, 20)}...');
    } catch (e) {
      print('⚠️ FCM Token alınamadı: $e');
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// BACKGROUND MESSAGE HANDLER (Top-level function)
/// Bu fonksiyon main.dart'ta import edilmeli ve Firebase.initializeApp'den sonra
/// FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)
/// olarak çağrılmalı
/// ═══════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background'da Firebase'i başlat (gerekirse)
  await Firebase.initializeApp();

  print('');
  print('📬 BACKGROUND MESAJ ALINDI:');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');

  // Background'da sadece log, UI güncellemesi yapılamaz
  // Kullanıcı bildirime tıklarsa onMessageOpenedApp tetiklenir
}
