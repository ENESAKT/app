import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timeago/timeago.dart' as timeago;

// Tema ve Konfigürasyon
import 'config/app_theme.dart';

import 'services/auth_provider.dart';
import 'services/database_seeder.dart';
import 'services/firebase_notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart'; // MainScaffold import
import 'screens/search_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/seed_data_screen.dart'; // DEV ONLY
import 'screens/apps_hub_screen.dart';
import 'screens/profile_screen.dart';
import 'features/wallpapers/screens/wallpapers_screen.dart';
import 'features/weather/screens/weather_screen.dart';
import 'features/news/screens/news_screen.dart';

/// Background message handler - Top-level function olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Background mesaj: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase initialization (FCM için gerekli)
  await Firebase.initializeApp();
  print('🔥 Firebase initialized');

  // 2. Background message handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Supabase initialization
  await Supabase.initialize(
    url: 'https://bmcbzkkewskuibojxvud.supabase.co',
    anonKey: 'sb_publishable_Ml7r3_OXOW2Tk_yOwm3TBQ_CUU1MTat',
  );

  // 4. Firebase Notification Service başlat (FCM Topic subscription)
  await FirebaseNotificationService().initialize();

  // 🌱 TEK SEFERLİK VERİTABANI SEED İŞLEMİ
  // ⚠️ Production'da bu kodu kaldırın!
  await _seedDatabaseOnce();

  // 5. Timeago Türkçe dil desteği
  timeago.setLocaleMessages('tr', timeago.TrMessages());

  runApp(const ProviderScope(child: MyApp()));
}

/// Veritabanını tek seferlik doldur (SharedPreferences ile kontrol)
Future<void> _seedDatabaseOnce() async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeeded = prefs.getBool('database_seeded') ?? false;

  if (!hasSeeded) {
    print('\n🌱 İLK ÇALIŞTIRMA TESPİT EDİLDİ - VERİTABANI SEED BAŞLIYOR...\n');

    try {
      final seeder = DatabaseSeeder();
      await seeder.seedDatabase();

      // İşlem başarılı, tekrar çalışmasın
      await prefs.setBool('database_seeded', true);
      print('\n✅ Veritabanı seed tamamlandı ve işaretlendi.\n');
    } catch (e) {
      print('\n❌ Seed hatası: $e');
      print('⚠️ Seed işlemi başarısız oldu. Uygulama devam edecek.\n');
      // Hata durumunda işaretleme YAPMA, bir sonraki açılışta tekrar denesin
    }
  } else {
    print('ℹ️ Veritabanı daha önce seed edilmiş, atlama yapılıyor.\n');
  }
}

// Global Supabase client (kolay erişim için)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Riverpod ile state management - ProviderScope main.dart'ta runApp'de
    return MaterialApp(
      title: 'Arkadaşlık Uygulaması',
      debugShowCheckedModeBanner: false,

      // ═══════════════════════════════════════════════════════════════════
      // KARANLIK TEMA - Modern ve şık görünüm
      // ═══════════════════════════════════════════════════════════════════
      theme: AppTheme.karanlikTema,
      darkTheme: AppTheme.karanlikTema,
      themeMode: ThemeMode.dark, // Her zaman karanlık mod
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        // Profile route with dynamic userId argument
        if (settings.name == '/profile') {
          final userId = settings.arguments as String?;
          if (userId != null) {
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            );
          }
        }
        return null; // Let routes table handle it
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const MainScaffold(), // MainScaffold kullan
        '/search': (context) => const SearchScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/conversations': (context) => const ConversationsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/blocked': (context) => const BlockedUsersScreen(),
        '/seed': (context) =>
            const SeedDataScreen(), // DEV ONLY - Remove in production
        // Super App Routes
        '/apps-hub': (context) => const AppsHubScreen(),
        '/wallpapers': (context) => const WallpapersScreen(),
        '/weather': (context) => const WeatherScreen(),
        '/news': (context) => const NewsScreen(),
      },
    );
  }
}

/// Auth Gate - Supabase onAuthStateChange ile oturum kontrolü
///
/// Oturum varsa MainScaffold'a yönlendirir (UpdateService otomatik init olur)
/// Oturum yoksa LoginScreen'e yönlendirir
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Bekleniyor durumu - Loading göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Oturum kontrolü
        final session = snapshot.data?.session;

        if (session != null) {
          // Oturum var -> MainScaffold (UpdateService burada init oluyor)
          return const MainScaffold();
        } else {
          // Oturum yok -> Giriş Ekranı
          return const LoginScreen();
        }
      },
    );
  }
}
