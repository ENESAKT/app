import 'dart:async';
import 'package:flutter/material.dart';

/// Akıllı Bekleme Ekranı Widget'ı
///
/// Özellikler:
/// - Yükleme animasyonu
/// - Bilgilendirme mesajları (zaman geçtikçe değişir)
/// - 90 saniye sonra "Tekrar Dene" butonu
class SmartLoadingWidget extends StatefulWidget {
  final String? title;
  final VoidCallback? onRetry;
  final bool showServerMessage;

  const SmartLoadingWidget({
    super.key,
    this.title,
    this.onRetry,
    this.showServerMessage = true,
  });

  @override
  State<SmartLoadingWidget> createState() => _SmartLoadingWidgetState();
}

class _SmartLoadingWidgetState extends State<SmartLoadingWidget>
    with SingleTickerProviderStateMixin {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showRetryButton = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds >= 90) {
            _showRetryButton = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _statusMessage {
    if (_elapsedSeconds < 5) {
      return 'Bağlanıyor...';
    } else if (_elapsedSeconds < 15) {
      return 'Sunucu başlatılıyor...';
    } else if (_elapsedSeconds < 30) {
      return 'Sunucu uyku modundan uyanıyor...';
    } else if (_elapsedSeconds < 60) {
      return 'Bu işlem ilk seferde 1 dakika sürebilir...';
    } else if (_elapsedSeconds < 90) {
      return 'Biraz daha bekleyin, neredeyse hazır!';
    } else {
      return 'Sunucu yanıt vermekte zorlanıyor...';
    }
  }

  Color get _progressColor {
    if (_elapsedSeconds < 30) return Colors.white;
    if (_elapsedSeconds < 60) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo/Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_pulseController.value * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Title
              if (widget.title != null)
                Text(
                  widget.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 30),

              // Progress Indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: _progressColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),

              // Status Message
              if (widget.showServerMessage)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              const SizedBox(height: 8),

              // Elapsed Time
              if (_elapsedSeconds > 10)
                Text(
                  '${_elapsedSeconds}s',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 30),

              // Retry Button (90 saniye sonra)
              if (_showRetryButton && widget.onRetry != null)
                Column(
                  children: [
                    const Text(
                      'Sunucu yanıt vermedi',
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _elapsedSeconds = 0;
                          _showRetryButton = false;
                        });
                        widget.onRetry!();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Loading Widget (Sayfa içi kullanım için)
class CompactLoadingWidget extends StatelessWidget {
  final String message;
  final bool showServerHint;

  const CompactLoadingWidget({
    super.key,
    this.message = 'Yükleniyor...',
    this.showServerHint = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (showServerHint) ...[
            const SizedBox(height: 8),
            Text(
              'Sunucu başlatılıyor, bekleyiniz...',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
