import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as app_models;

/// Global AuthProvider instance for Riverpod
final authProvider = ChangeNotifierProvider<AuthProvider>(
  (ref) => AuthProvider(),
);

/// Auth Provider - Supabase Native Authentication
///
/// Firebase'den TAMAMEN bağımsız, Supabase Auth kullanır.
/// Bu sayede user.id her zaman geçerli bir UUID olur.
class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  app_models.User? _currentUser;
  User? _supabaseUser;
  bool _isLoading = false;
  String? _error;

  app_models.User? get currentUser => _currentUser;
  User? get supabaseUser => _supabaseUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _supabaseUser != null;
  String? get error => _error;

  /// Supabase user ID (UUID formatında)
  String? get userId => _supabaseUser?.id;

  // ==================== SESSION CHECK ====================

  /// Mevcut oturumu kontrol et
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        _supabaseUser = session.user;

        // UUID format kontrolü - Supabase UUID formatı
        if (_supabaseUser != null) {
          final userId = _supabaseUser!.id;

          // UUID format validation (8-4-4-4-12 characters)
          final uuidRegex = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          );

          if (!uuidRegex.hasMatch(userId)) {
            print('⚠️ Geçersiz UUID formatı tespit edildi: $userId');
            print('🔄 Eski oturum temizleniyor...');
            await signOut();
            _isLoading = false;
            notifyListeners();
            return;
          }

          // Kullanıcı bilgilerini users tablosundan al
          await _loadUserProfile();
        }
      }
    } catch (e) {
      print('❌ Auth check hatası: $e');
      // Hata durumunda oturumu temizle
      await signOut();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Auth durumu değişikliklerini dinle
  void listenAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      print('🔔 Auth event: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        _supabaseUser = session.user;
        _loadUserProfile();
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _supabaseUser = null;
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // ==================== GOOGLE SIGN IN (Supabase OAuth) ====================

  /// Google ile giriş yap (Supabase Native OAuth)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Supabase Google OAuth başlatılıyor...');

      // Supabase Native Google OAuth
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.arkadas://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        _error = 'Google girişi başlatılamadı';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // OAuth akışı başlatıldı, callback beklenecek
      // Auth state listener ile işlenecek
      print('✅ Google OAuth akışı başlatıldı');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Google sign in hatası: $e');
      _error = 'Google girişi başarısız: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== EMAIL/PASSWORD AUTH ====================

  /// E-posta ile kayıt ol
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 Supabase email kayıt başlatılıyor...');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': email.split('@').first,
        },
      );

      if (response.user == null) {
        _error = 'Kayıt başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _supabaseUser = response.user;

      // Users tablosuna profil ekle
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        username: email.split('@').first,
        displayName: '$firstName $lastName',
      );

      print('✅ Kayıt başarılı: ${response.user!.id}');

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      print('❌ Supabase auth hatası: ${e.message}');
      _error = _getSupabaseErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Kayıt genel hatası: $e');
      _error = 'Kayıt hatası: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// E-posta ile giriş yap
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Supabase email giriş başlatılıyor...');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _error = 'Giriş başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _supabaseUser = response.user;
      await _loadUserProfile();

      print('✅ Giriş başarılı: ${response.user!.id}');

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      print('❌ Supabase auth hatası: ${e.message}');
      _error = _getSupabaseErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Giriş genel hatası: $e');
      _error = 'Giriş hatası: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== SIGN OUT ====================

  /// Çıkış yap
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
      print('✅ Çıkış yapıldı');
    } catch (e) {
      print('⚠️ Çıkış hatası (ignored): $e');
    }

    _supabaseUser = null;
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Kullanıcı profilini yükle
  Future<void> _loadUserProfile() async {
    if (_supabaseUser == null) return;

    try {
      final userId = _supabaseUser!.id;
      print('📥 Profil yükleniyor: $userId');

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _currentUser = app_models.User(
          id: 0, // Local ID, Supabase UUID farklı
          username:
              response['username'] ??
              _supabaseUser!.email?.split('@').first ??
              'user',
          email: response['email'] ?? _supabaseUser!.email ?? '',
          firstName: response['first_name'] ?? '',
          lastName: response['last_name'] ?? '',
          profilePhoto: response['avatar_url'],
          isAdminUser: response['is_admin'] ?? false,
        );
        print('✅ Profil yüklendi: ${_currentUser!.username}');
      } else {
        // Profil yoksa oluştur (OAuth kullanıcıları için)
        await _createUserProfile(
          userId: userId,
          email: _supabaseUser!.email ?? '',
          username: _supabaseUser!.email?.split('@').first ?? 'user',
          displayName: _supabaseUser!.userMetadata?['full_name'],
          avatarUrl: _supabaseUser!.userMetadata?['avatar_url'],
        );
      }
    } catch (e) {
      print('❌ Profil yükleme hatası: $e');
    }
  }

  /// Kullanıcı profili oluştur (users tablosuna)
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      // Ad soyad ayır
      String firstName = '';
      String lastName = '';
      if (displayName != null && displayName.isNotEmpty) {
        final parts = displayName.split(' ');
        firstName = parts.first;
        lastName = parts.skip(1).join(' ');
      }

      await _supabase.from('users').upsert({
        'id': userId,
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'avatar_url': avatarUrl,
        'is_online': true,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('✅ Profil oluşturuldu/güncellendi: $username');

      // Local model güncelle
      _currentUser = app_models.User(
        id: 0,
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        profilePhoto: avatarUrl,
        isAdminUser: false,
      );
    } catch (e) {
      print('❌ Profil oluşturma hatası: $e');
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Supabase hata mesajlarını Türkçeye çevir
  String _getSupabaseErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-posta veya şifre hatalı';
    }
    if (message.contains('Email not confirmed')) {
      return 'E-posta adresi doğrulanmamış';
    }
    if (message.contains('User already registered')) {
      return 'Bu e-posta adresi zaten kullanılıyor';
    }
    if (message.contains('Password should be at least')) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (message.contains('Invalid email')) {
      return 'Geçersiz e-posta adresi';
    }
    if (message.contains('Network')) {
      return 'İnternet bağlantısını kontrol edin';
    }
    return message;
  }

  /// Hatayı temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
