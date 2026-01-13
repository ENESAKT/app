import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_provider.dart';
import 'services/database_seeder.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/seed_data_screen.dart'; // DEV ONLY
import 'widgets/smart_loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization (Firebase KALDIRILDI)
  await Supabase.initialize(
    url: 'https://bmcbzkkewskuibojxvud.supabase.co',
    anonKey: 'sb_publishable_Ml7r3_OXOW2Tk_yOwm3TBQ_CUU1MTat',
  );

  // 🌱 TEK SEFERLİK VERİTABANI SEED İŞLEMİ
  // ⚠️ Production'da bu kodu kaldırın!
  await _seedDatabaseOnce();

  runApp(const MyApp());
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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Arkadaşlık Uygulaması',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
          '/friends': (context) => const FriendsScreen(),
          '/conversations': (context) => const ConversationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/admin': (context) => const AdminPanelScreen(),
          '/blocked': (context) => const BlockedUsersScreen(),
          '/seed': (context) =>
              const SeedDataScreen(), // DEV ONLY - Remove in production
        },
      ),
    );
  }
}

/// Auth Wrapper - Oturum durumuna göre yönlendirme
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Uygulama başlarken auth kontrolü yap (async, bloklamadan)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuth();
    });
  }

  void _retryAuth() {
    Provider.of<AuthProvider>(context, listen: false).checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Yükleniyor - Akıllı Bekleme Ekranı
        if (auth.isLoading) {
          return Scaffold(
            body: SmartLoadingWidget(
              title: 'Arkadaşlık',
              showServerMessage: true,
              onRetry: _retryAuth,
            ),
          );
        }

        // Giriş yapılmış -> MainLayout
        if (auth.isLoggedIn) {
          return const MainScaffold();
        }

        // Giriş yapılmamış -> Login
        return const LoginScreen();
      },
    );
  }
}
