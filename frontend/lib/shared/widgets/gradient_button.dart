import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GRADİENT BUTON - Mor-Turuncu Geçişli Modern Buton
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Kullanım:
/// ```dart
/// GradientButton(
///   metin: 'Giriş Yap',
///   onPressed: () => print('Tıklandı'),
/// )
/// ```

class GradientButton extends StatelessWidget {
  /// Buton üzerindeki metin
  final String metin;

  /// Tıklama fonksiyonu
  final VoidCallback? onPressed;

  /// Buton genişliği (null ise içeriğe göre)
  final double? genislik;

  /// Buton yüksekliği
  final double yukseklik;

  /// Köşe yuvarlaklığı
  final double koseYaricapi;

  /// Sol tarafta gösterilecek ikon (opsiyonel)
  final IconData? ikon;

  /// Yükleniyor durumu
  final bool yukleniyor;

  /// Özel gradient (opsiyonel)
  final Gradient? ozelGradient;

  /// Metin stili (opsiyonel)
  final TextStyle? metinStili;

  const GradientButton({
    super.key,
    required this.metin,
    this.onPressed,
    this.genislik,
    this.yukseklik = 52,
    this.koseYaricapi = 26,
    this.ikon,
    this.yukleniyor = false,
    this.ozelGradient,
    this.metinStili,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: genislik,
      height: yukseklik,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? (ozelGradient ?? AppTheme.anaGradient)
            : null,
        color: onPressed == null ? AppTheme.metinSoluk : null,
        borderRadius: BorderRadius.circular(koseYaricapi),
        boxShadow: onPressed != null ? AppTheme.vurguGolgesi : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: yukleniyor ? null : onPressed,
          borderRadius: BorderRadius.circular(koseYaricapi),
          child: Center(
            child: yukleniyor
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (ikon != null) ...[
                        Icon(ikon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        metin,
                        style:
                            metinStili ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GRADİENT KENARSIZ BUTON - Sadece metin/ikon gradient'li
/// ═══════════════════════════════════════════════════════════════════════════

class GradientTextButton extends StatelessWidget {
  final String metin;
  final VoidCallback? onPressed;
  final IconData? ikon;
  final double fontSize;

  const GradientTextButton({
    super.key,
    required this.metin,
    this.onPressed,
    this.ikon,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: ShaderMask(
        shaderCallback: (bounds) => AppTheme.anaGradient.createShader(bounds),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon != null) ...[
              Icon(ikon, color: Colors.white, size: fontSize + 4),
              const SizedBox(width: 6),
            ],
            Text(
              metin,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
