import 'package:flutter/material.dart';
import '../services/database_seeder.dart';

/// Test için veritabanı seed ekranı
/// GELİŞTİRME AMAÇLI - Üretimde kaldırılmalı
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  bool _isSeeding = false;
  String _status = 'Hazır';

  Future<void> _startSeeding() async {
    setState(() {
      _isSeeding = true;
      _status = 'Kullanıcılar oluşturuluyor...';
    });

    try {
      await _seeder.seedDatabase();

      setState(() {
        _status = '✅ 50 Kullanıcı Başarıyla Eklendi!';
        _isSeeding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Veritabanı seed işlemi tamamlandı!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Hata: $e';
        _isSeeding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Seeder'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _isSeeding ? Icons.hourglass_empty : Icons.cloud_upload,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Veritabanı Seed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                '50 test kullanıcısı oluşturulacak\nŞifre: 123456',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSeeding)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.orange),
                        ),
                      ),
                    if (_isSeeding) const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Seed Button
              ElevatedButton.icon(
                onPressed: _isSeeding ? null : _startSeeding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Seed Başlat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Bu ekran sadece geliştirme amaçlıdır!\nÜretimde kaldırılmalıdır.',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
