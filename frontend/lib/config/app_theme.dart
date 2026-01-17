import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UYGULAMA TEMASI - Modern Karanlık Tasarım
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Bu dosya, uygulamanın tüm görsel stilini tanımlar:
/// - Karanlık arka plan renkleri (#121212, #1E1E1E)
/// - Mor-Turuncu gradient yapısı
/// - Modern tipografi (Inter/Poppins)
/// - Glassmorphism efekt ayarları

class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // ANA RENKLER
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana arka plan rengi - Derin siyah
  static const Color arkaplanKoyu = Color(0xFF121212);

  /// İkincil arka plan rengi - Koyu gri
  static const Color arkaplanAcik = Color(0xFF1E1E1E);

  /// Kart arka plan rengi
  static const Color kartArkaplani = Color(0xFF2A2A2A);

  /// Yüzey rengi (Modal, BottomSheet vb.)
  static const Color yuzeyRengi = Color(0xFF252525);

  /// Kenar çizgisi rengi
  static const Color kenarRengi = Color(0xFF3A3A3A);

  // ══════════════════════════════════════════════════════════════════════════
  // VURGU RENKLERİ (Gradient için)
  // ══════════════════════════════════════════════════════════════════════════

  /// Mor renk - Gradient başlangıç
  static const Color morVurgu = Color(0xFF7B2FFE);

  /// Turuncu/Pembe renk - Gradient bitiş
  static const Color turuncuVurgu = Color(0xFFFF6B6B);

  /// Alternatif pembe
  static const Color pembeVurgu = Color(0xFFE91E8C);

  /// Mavi vurgu
  static const Color maviVurgu = Color(0xFF4ECDC4);

  // ══════════════════════════════════════════════════════════════════════════
  // METİN RENKLERİ
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana metin rengi - Beyaz
  static const Color metinAna = Color(0xFFFFFFFF);

  /// İkincil metin rengi - Açık gri
  static const Color metinIkincil = Color(0xFFB3B3B3);

  /// Soluk metin rengi
  static const Color metinSoluk = Color(0xFF757575);

  /// Devre dışı metin
  static const Color metinDevreDisi = Color(0xFF505050);

  // ══════════════════════════════════════════════════════════════════════════
  // GRADİENT TANIMLARI
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana mor-turuncu gradient (Butonlar ve vurgular için)
  static const LinearGradient anaGradient = LinearGradient(
    colors: [morVurgu, turuncuVurgu],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Mor-pembe gradient alternatif
  static const LinearGradient morPembeGradient = LinearGradient(
    colors: [morVurgu, pembeVurgu],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dikey gradient (AppBar ve header için)
  static const LinearGradient dikeyGradient = LinearGradient(
    colors: [morVurgu, turuncuVurgu],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Cam efekti için şeffaf gradient
  static LinearGradient camEfektiGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.15),
      Colors.white.withValues(alpha: 0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // GLASSMORPHISM (CAM EFEKTİ) AYARLARI
  // ══════════════════════════════════════════════════════════════════════════

  /// Cam efekti bulanıklık değeri
  static const double camBulaniklik = 10.0;

  /// Cam efekti kenarlık
  static BoxDecoration camEfektiDekorasyon({
    double bulaniklik = 10.0,
    double kenarYaricapi = 16.0,
    Color? arkaplan,
  }) {
    return BoxDecoration(
      color: arkaplan ?? Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(kenarYaricapi),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // YUVARLATILMİŞ KÖŞE DEĞERLERİ
  // ══════════════════════════════════════════════════════════════════════════

  static const double koseKucuk = 8.0;
  static const double koseOrta = 12.0;
  static const double koseBuyuk = 16.0;
  static const double koseYuvarlak = 24.0;
  static const double koseTamYuvarlak = 50.0;

  // ══════════════════════════════════════════════════════════════════════════
  // GÖLGE TANIMLARI
  // ══════════════════════════════════════════════════════════════════════════

  /// Hafif gölge
  static List<BoxShadow> hafifGolge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Orta gölge
  static List<BoxShadow> ortaGolge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// Vurgu gölgesi (Gradient butonlar için)
  static List<BoxShadow> vurguGolgesi = [
    BoxShadow(
      color: morVurgu.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // FLUTTER THEME DATA - KARANLIK TEMA
  // ══════════════════════════════════════════════════════════════════════════

  /// Uygulamanın ana karanlık teması
  static ThemeData karanlikTema = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Ana renkler
    primaryColor: morVurgu,
    scaffoldBackgroundColor: arkaplanKoyu,

    // Renk şeması
    colorScheme: const ColorScheme.dark(
      primary: morVurgu,
      secondary: turuncuVurgu,
      surface: yuzeyRengi,
      error: Color(0xFFFF5252),
      onPrimary: metinAna,
      onSecondary: metinAna,
      onSurface: metinAna,
      onError: metinAna,
    ),

    // Yazı tipi ailesi
    fontFamily: 'Inter',

    // Metin stilleri
    textTheme: const TextTheme(
      // Başlıklar
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: metinAna,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: metinAna,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: metinAna,
      ),

      // Sayfa başlıkları
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: metinAna,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: metinAna,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: metinAna,
      ),

      // Etiketler ve başlıklar
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: metinAna,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: metinAna,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: metinIkincil,
      ),

      // Gövde metinleri
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: metinAna,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: metinIkincil,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: metinSoluk,
      ),

      // Etiket metinleri
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: metinAna,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: metinIkincil,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: metinSoluk,
      ),
    ),

    // AppBar teması
    appBarTheme: const AppBarTheme(
      backgroundColor: arkaplanKoyu,
      foregroundColor: metinAna,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: metinAna,
        fontFamily: 'Inter',
      ),
      iconTheme: IconThemeData(color: metinAna),
    ),

    // Alt navigasyon çubuğu
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: arkaplanAcik,
      selectedItemColor: morVurgu,
      unselectedItemColor: metinSoluk,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Kart teması
    cardTheme: CardThemeData(
      color: kartArkaplani,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(koseBuyuk),
        side: BorderSide(color: kenarRengi.withValues(alpha: 0.5)),
      ),
    ),

    // Elevated button teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: morVurgu,
        foregroundColor: metinAna,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(koseYuvarlak),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),

    // Outlined button teması
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: metinAna,
        side: const BorderSide(color: kenarRengi),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(koseYuvarlak),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    ),

    // Text button teması
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: morVurgu,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    ),

    // Input (TextField) dekorasyonu
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: yuzeyRengi,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseOrta),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseOrta),
        borderSide: BorderSide(color: kenarRengi.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseOrta),
        borderSide: const BorderSide(color: morVurgu, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(koseOrta),
        borderSide: const BorderSide(color: Color(0xFFFF5252)),
      ),
      hintStyle: const TextStyle(color: metinSoluk),
      labelStyle: const TextStyle(color: metinIkincil),
    ),

    // Dialog teması
    dialogTheme: DialogThemeData(
      backgroundColor: yuzeyRengi,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(koseBuyuk),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: metinAna,
        fontFamily: 'Inter',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: metinIkincil,
        fontFamily: 'Inter',
      ),
    ),

    // BottomSheet teması
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: yuzeyRengi,
      modalBackgroundColor: yuzeyRengi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Snackbar teması
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kartArkaplani,
      contentTextStyle: const TextStyle(color: metinAna),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(koseOrta),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Floating action button teması
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: morVurgu,
      foregroundColor: metinAna,
      elevation: 4,
    ),

    // IconButton teması
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: metinAna),
    ),

    // Divider teması
    dividerTheme: DividerThemeData(
      color: kenarRengi.withValues(alpha: 0.5),
      thickness: 1,
    ),

    // Chip teması
    chipTheme: ChipThemeData(
      backgroundColor: yuzeyRengi,
      selectedColor: morVurgu,
      disabledColor: kartArkaplani,
      labelStyle: const TextStyle(color: metinAna),
      secondaryLabelStyle: const TextStyle(color: metinAna),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(koseTamYuvarlak),
        side: BorderSide(color: kenarRengi.withValues(alpha: 0.5)),
      ),
    ),

    // Switch teması
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return morVurgu;
        return metinSoluk;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return morVurgu.withValues(alpha: 0.5);
        return kenarRengi;
      }),
    ),

    // Slider teması
    sliderTheme: SliderThemeData(
      activeTrackColor: morVurgu,
      inactiveTrackColor: kenarRengi,
      thumbColor: morVurgu,
      overlayColor: morVurgu.withValues(alpha: 0.2),
    ),

    // ListTile teması
    listTileTheme: const ListTileThemeData(
      textColor: metinAna,
      iconColor: metinIkincil,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
  );
}
