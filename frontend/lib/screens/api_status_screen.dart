import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/constants/api_keys.dart';

/// API Status Screen - Tüm API durumlarını gösteren ekran
class ApiStatusScreen extends StatefulWidget {
  const ApiStatusScreen({super.key});
  @override
  State<ApiStatusScreen> createState() => _ApiStatusScreenState();
}

class _ApiInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String? testUrl;
  final bool hasApiKey;
  bool isLoading;
  bool? isOnline;
  String? responseTime;
  String? error;

  _ApiInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.testUrl,
    required this.hasApiKey,
    this.isLoading = false,
    this.isOnline,
    this.responseTime,
    this.error,
  });
}

class _ApiStatusScreenState extends State<ApiStatusScreen> {
  DateTime _currentTime = DateTime.now();
  late List<_ApiInfo> _apis;

  @override
  void initState() {
    super.initState();
    _initApis();
    _checkAllApis();
    // Saati güncelle
    Future.delayed(Duration.zero, _updateClock);
  }

  void _updateClock() {
    if (mounted) {
      setState(() => _currentTime = DateTime.now());
      Future.delayed(const Duration(seconds: 1), _updateClock);
    }
  }

  void _initApis() {
    _apis = [
      _ApiInfo(
        name: 'CoinGecko',
        description: 'Kripto para fiyatları',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFFF7931A),
        testUrl: 'https://api.coingecko.com/api/v3/ping',
        hasApiKey: ApiKeys.coinGecko.isNotEmpty,
      ),
      _ApiInfo(
        name: 'Gemini AI',
        description: 'Google AI sohbet',
        icon: Icons.auto_awesome,
        color: const Color(0xFF4285F4),
        testUrl: null,
        hasApiKey: ApiKeys.googleGemini.isNotEmpty,
      ),
      _ApiInfo(
        name: 'Geoapify',
        description: 'Harita servisi',
        icon: Icons.map,
        color: const Color(0xFF34A853),
        testUrl:
            'https://api.geoapify.com/v1/geocode/search?text=Istanbul&apiKey=${ApiKeys.geoapify}',
        hasApiKey: ApiKeys.geoapify.isNotEmpty,
      ),
      _ApiInfo(
        name: 'REST Countries',
        description: 'Ülke bilgileri',
        icon: Icons.public,
        color: const Color(0xFF8E44AD),
        testUrl: 'https://restcountries.com/v3.1/name/turkey?fields=name',
        hasApiKey: true,
      ),
      _ApiInfo(
        name: 'Hugging Face',
        description: 'AI duygu analizi',
        icon: Icons.psychology,
        color: const Color(0xFF667EEA),
        testUrl: null,
        hasApiKey: ApiKeys.huggingFace.isNotEmpty,
      ),
      _ApiInfo(
        name: 'Finnhub',
        description: 'Borsa verileri',
        icon: Icons.show_chart,
        color: const Color(0xFF00C853),
        testUrl:
            'https://finnhub.io/api/v1/quote?symbol=AAPL&token=${ApiKeys.finnhub}',
        hasApiKey: ApiKeys.finnhub.isNotEmpty,
      ),
      _ApiInfo(
        name: 'ExchangeRate',
        description: 'Döviz kurları',
        icon: Icons.currency_exchange,
        color: const Color(0xFF1ABC9C),
        testUrl:
            'https://v6.exchangerate-api.com/v6/${ApiKeys.exchangeRate}/latest/USD',
        hasApiKey: ApiKeys.exchangeRate.isNotEmpty,
      ),
      _ApiInfo(
        name: 'Pollinations',
        description: 'Görsel üretme (ücretsiz)',
        icon: Icons.image,
        color: const Color(0xFF9B59B6),
        testUrl: 'https://image.pollinations.ai/prompt/test',
        hasApiKey: true,
      ),
      _ApiInfo(
        name: 'Picsum',
        description: 'Galeri görselleri',
        icon: Icons.photo_library,
        color: const Color(0xFFE91E63),
        testUrl: 'https://picsum.photos/v2/list?page=1&limit=1',
        hasApiKey: true,
      ),
    ];
  }

  Future<void> _checkAllApis() async {
    for (var api in _apis) {
      await _checkApi(api);
    }
  }

  Future<void> _checkApi(_ApiInfo api) async {
    if (api.testUrl == null) {
      setState(() {
        api.isOnline = api.hasApiKey;
        api.responseTime = api.hasApiKey ? 'Key mevcut' : 'Key yok';
      });
      return;
    }
    setState(() => api.isLoading = true);
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse(api.testUrl!))
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();
      setState(() {
        api.isLoading = false;
        api.isOnline = response.statusCode == 200;
        api.responseTime = '${stopwatch.elapsedMilliseconds}ms';
        api.error = response.statusCode != 200
            ? 'HTTP ${response.statusCode}'
            : null;
      });
    } catch (e) {
      setState(() {
        api.isLoading = false;
        api.isOnline = false;
        api.error = e.toString().split(':').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'API Durumu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: _checkAllApis,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTimeCard(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _apis.length,
                  itemBuilder: (ctx, i) => _buildApiCard(_apis[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            timeFormat.format(_currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(_currentTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusChip(
                'Çevrimiçi',
                _apis.where((a) => a.isOnline == true).length,
                Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildStatusChip(
                'Çevrimdışı',
                _apis.where((a) => a.isOnline == false).length,
                Colors.redAccent,
              ),
              const SizedBox(width: 12),
              _buildStatusChip(
                'Kontrol',
                _apis.where((a) => a.isLoading).length,
                Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiCard(_ApiInfo api) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: api.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(api.icon, color: api.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        api.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        api.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      if (api.responseTime != null)
                        Text(
                          api.responseTime!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (api.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          (api.isOnline == true
                                  ? Colors.green
                                  : api.isOnline == false
                                  ? Colors.red
                                  : Colors.grey)
                              .withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      api.isOnline == true
                          ? Icons.check
                          : api.isOnline == false
                          ? Icons.close
                          : Icons.help_outline,
                      color: api.isOnline == true
                          ? Colors.greenAccent
                          : api.isOnline == false
                          ? Colors.redAccent
                          : Colors.grey,
                      size: 18,
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
