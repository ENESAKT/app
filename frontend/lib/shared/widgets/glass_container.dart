import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CAM EFEKTLİ KONTEYNER (GLASSMORPHISM)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Bulanık arka plan ve yarı şeffaf yüzey ile modern cam efekti.
///
/// Kullanım:
/// ```dart
/// GlassContainer(
///   child: Text('Cam efektli içerik'),
///   padding: EdgeInsets.all(16),
/// )
/// ```

class GlassContainer extends StatelessWidget {
  /// İç içerik
  final Widget child;

  /// İç boşluk
  final EdgeInsetsGeometry? padding;

  /// Dış boşluk
  final EdgeInsetsGeometry? margin;

  /// Genişlik
  final double? width;

  /// Yükseklik
  final double? height;

  /// Köşe yarıçapı
  final double borderRadius;

  /// Bulanıklık değeri
  final double blur;

  /// Arka plan opaklığı (0.0 - 1.0)
  final double opacity;

  /// Kenarlık göster
  final bool showBorder;

  /// Özel arka plan rengi
  final Color? backgroundColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.1,
    this.showBorder = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CAM EFEKTLİ KART
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Tıklanabilir cam efektli kart widget'ı

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: blur,
      borderRadius: borderRadius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// KOYU CAM KONTEYNER
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Karanlık tema için koyu tonlu cam efekti

class DarkGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;

  const DarkGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      borderRadius: borderRadius,
      blur: blur,
      backgroundColor: AppTheme.kartArkaplani.withValues(alpha: 0.7),
      child: child,
    );
  }
}
