import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_keys.dart';

/// Crypto Screen - CoinGecko API ile Kripto Paralar
class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});
  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoCoin {
  final String id, name, symbol, image;
  final double currentPrice, priceChangePercent24h, marketCap;
  final int rank;
  _CryptoCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercent24h,
    required this.marketCap,
    required this.rank,
  });
  factory _CryptoCoin.fromJson(Map<String, dynamic> json) => _CryptoCoin(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    symbol: (json['symbol'] ?? '').toUpperCase(),
    image: json['image'] ?? '',
    currentPrice: (json['current_price'] ?? 0).toDouble(),
    priceChangePercent24h: (json['price_change_percentage_24h'] ?? 0)
        .toDouble(),
    marketCap: (json['market_cap'] ?? 0).toDouble(),
    rank: json['market_cap_rank'] ?? 0,
  );
}

class _CryptoScreenState extends State<CryptoScreen> {
  List<_CryptoCoin> _coins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final headers = ApiKeys.coinGecko.isNotEmpty
          ? {'x-cg-demo-api-key': ApiKeys.coinGecko}
          : <String, String>{};
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=25&page=1&sparkline=false',
        ),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _coins = data.map((e) => _CryptoCoin.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
          'Kripto Paralar',
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
            onPressed: _loadCoins,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7931A), Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _error != null
              ? _buildError()
              : _buildList(),
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          'Kripto paralar yükleniyor...',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.white54, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Veriler yüklenemedi',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadCoins,
          icon: const Icon(Icons.refresh),
          label: const Text('Tekrar Dene'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
          ),
        ),
      ],
    ),
  );

  Widget _buildList() => RefreshIndicator(
    onRefresh: _loadCoins,
    color: Colors.orange,
    backgroundColor: Colors.white,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coins.length,
      itemBuilder: (ctx, i) => _buildCoinCard(_coins[i]),
    ),
  );

  Widget _buildCoinCard(_CryptoCoin coin) {
    final isPositive = coin.priceChangePercent24h >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coin.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          coin.symbol[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coin.symbol,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${coin.rank}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_formatPrice(coin.currentPrice)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${coin.priceChangePercent24h.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isPositive
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000)
      return price
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    if (price >= 1) return price.toStringAsFixed(2);
    return price.toStringAsFixed(4);
  }
}
