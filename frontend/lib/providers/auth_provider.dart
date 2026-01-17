import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTH PROVIDER - Supabase Oturum Yönetimi (Riverpod)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Bu dosya Supabase authentication akışını Riverpod ile yönetir.
/// - currentUserProvider: Anlık oturum durumunu dinler
/// - userIdProvider: Sadece kullanıcı ID'sini döndürür
/// - isLoggedInProvider: Oturum açık mı kontrol eder

// ══════════════════════════════════════════════════════════════════════════
// SUPABASE CLIENT
// ══════════════════════════════════════════════════════════════════════════

/// Supabase client'a kolay erişim
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ══════════════════════════════════════════════════════════════════════════
// AUTH STATE STREAM
// ══════════════════════════════════════════════════════════════════════════

/// Supabase onAuthStateChange akışını dinleyen StreamProvider
/// Oturum değişikliklerini gerçek zamanlı takip eder
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// ══════════════════════════════════════════════════════════════════════════
// MEVCUT KULLANICI
// ══════════════════════════════════════════════════════════════════════════

/// Mevcut oturum açmış kullanıcıyı döndürür (null olabilir)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user).value;
});

/// Mevcut kullanıcının ID'si (null olabilir)
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

/// Oturum açık mı kontrolü
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ══════════════════════════════════════════════════════════════════════════
// KULLANICI PROFİLİ
// ══════════════════════════════════════════════════════════════════════════

/// Mevcut kullanıcının profil bilgilerini veritabanından çeker
final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  } catch (e) {
    print('❌ Kullanıcı profili çekme hatası: $e');
    return null;
  }
});

// ══════════════════════════════════════════════════════════════════════════
// AUTH İŞLEMLERİ (NOTIFIER)
// ══════════════════════════════════════════════════════════════════════════

/// Auth işlemleri için state
class AuthNotifierState {
  final bool isLoading;
  final String? error;

  const AuthNotifierState({this.isLoading = false, this.error});

  AuthNotifierState copyWith({bool? isLoading, String? error}) {
    return AuthNotifierState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth işlemlerini yöneten Notifier
class AuthNotifier extends StateNotifier<AuthNotifierState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthNotifierState());

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  /// E-posta ile giriş yap
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Giriş başarısız: $e');
      return false;
    }
  }

  /// E-posta ile kayıt ol
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName, 'last_name': lastName},
      );

      // Kullanıcı profilini oluştur
      if (response.user != null) {
        await _client.from('users').upsert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'username': email.split('@').first,
        });
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Kayıt başarısız: $e');
      return false;
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _client.auth.signOut();
    state = state.copyWith(isLoading: false);
  }

  /// Hata mesajını temizle
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// AuthNotifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthNotifierState>((ref) {
      return AuthNotifier(ref);
    });
