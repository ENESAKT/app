import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UYGULAMA RENKLERİ - Kolay Erişim İçin Statik Sabitler
/// ═══════════════════════════════════════════════════════════════════════════

class AppColors {
  // Private constructor - Instance oluşturulamaz
  AppColors._();

  // ══════════════════════════════════════════════════════════════════════════
  // ARKA PLAN RENKLERİ
  // ══════════════════════════════════════════════════════════════════════════

  /// Derin siyah arka plan
  static const Color arkaplan = Color(0xFF121212);

  /// Koyu gri arka plan
  static const Color arkaplanAcik = Color(0xFF1E1E1E);

  /// Yüzey rengi
  static const Color yuzey = Color(0xFF252525);

  /// Kart arka planı
  static const Color kart = Color(0xFF2A2A2A);

  /// Kenar/Ayırıcı rengi
  static const Color kenar = Color(0xFF3A3A3A);

  // ══════════════════════════════════════════════════════════════════════════
  // VURGU RENKLERİ
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana mor renk
  static const Color mor = Color(0xFF7B2FFE);

  /// Koyu mor
  static const Color morKoyu = Color(0xFF5B1DBD);

  /// Açık mor
  static const Color morAcik = Color(0xFF9B5BFF);

  /// Turuncu vurgu
  static const Color turuncu = Color(0xFFFF6B6B);

  /// Pembe vurgu
  static const Color pembe = Color(0xFFE91E8C);

  /// Mavi vurgu
  static const Color mavi = Color(0xFF4ECDC4);

  /// Yeşil (Başarı) rengi
  static const Color yesil = Color(0xFF4CAF50);

  /// Kırmızı (Hata) rengi
  static const Color kirmizi = Color(0xFFFF5252);

  /// Sarı (Uyarı) rengi
  static const Color sari = Color(0xFFFFD93D);

  // ══════════════════════════════════════════════════════════════════════════
  // METİN RENKLERİ
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana metin - Beyaz
  static const Color metin = Color(0xFFFFFFFF);

  /// İkincil metin - Açık gri
  static const Color metinIkincil = Color(0xFFB3B3B3);

  /// Soluk metin
  static const Color metinSoluk = Color(0xFF757575);

  /// Pasif/Devre dışı metin
  static const Color metinPasif = Color(0xFF505050);

  // ══════════════════════════════════════════════════════════════════════════
  // GRADİENT LİSTELERİ (Kolayca kullanım için)
  // ══════════════════════════════════════════════════════════════════════════

  /// Mor-Turuncu gradient renkleri
  static const List<Color> gradientMorTuruncu = [mor, turuncu];

  /// Mor-Pembe gradient renkleri
  static const List<Color> gradientMorPembe = [mor, pembe];

  /// Mavi-Mor gradient renkleri
  static const List<Color> gradientMaviMor = [mavi, mor];

  // ══════════════════════════════════════════════════════════════════════════
  // HAZIR GRADİENTLER
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana gradient - Mor'dan Turuncu'ya
  static const LinearGradient anaGradient = LinearGradient(
    colors: gradientMorTuruncu,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dikey gradient
  static const LinearGradient dikeyGradient = LinearGradient(
    colors: gradientMorTuruncu,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Yatay gradient
  static const LinearGradient yatayGradient = LinearGradient(
    colors: gradientMorTuruncu,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
