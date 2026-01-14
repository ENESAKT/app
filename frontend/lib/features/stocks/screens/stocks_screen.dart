import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_keys.dart';

/// Stocks Screen - Finnhub API ile Borsa
class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});
  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StockQuote {
  final String symbol, name, logo;
  final double current, previousClose, change, changePercent, high, low;
  _StockQuote({
    required this.symbol,
    required this.name,
    required this.logo,
    required this.current,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
  });
}

class _StocksScreenState extends State<StocksScreen> {
  final List<Map<String, String>> _stocks = [
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'logo': '🍎'},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'logo': '🚗'},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'logo': '🔍'},
    {'symbol': 'MSFT', 'name': 'Microsoft', 'logo': '💻'},
    {'symbol': 'AMZN', 'name': 'Amazon', 'logo': '📦'},
    {'symbol': 'META', 'name': 'Meta Platforms', 'logo': '👤'},
    {'symbol': 'NVDA', 'name': 'NVIDIA', 'logo': '🎮'},
    {'symbol': 'NFLX', 'name': 'Netflix', 'logo': '🎬'},
  ];
  final Map<String, _StockQuote> _quotes = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      for (var stock in _stocks) {
        final symbol = stock['symbol']!;
        final response = await http.get(
          Uri.parse(
            'https://finnhub.io/api/v1/quote?symbol=$symbol&token=${ApiKeys.finnhub}',
          ),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _quotes[symbol] = _StockQuote(
            symbol: symbol,
            name: stock['name']!,
            logo: stock['logo']!,
            current: (data['c'] ?? 0).toDouble(),
            previousClose: (data['pc'] ?? 0).toDouble(),
            change: (data['d'] ?? 0).toDouble(),
            changePercent: (data['dp'] ?? 0).toDouble(),
            high: (data['h'] ?? 0).toDouble(),
            low: (data['l'] ?? 0).toDouble(),
          );
        }
        await Future.delayed(const Duration(milliseconds: 200)); // Rate limit
      }
      setState(() => _isLoading = false);
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
          'Borsa',
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
            onPressed: _loadQuotes,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00C853), Color(0xFF1B5E20), Color(0xFF4CAF50)],
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
          'Hisse fiyatları yükleniyor...',
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
        Text(
          'Finnhub API hatası',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'API key kontrol edin',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadQuotes,
          icon: const Icon(Icons.refresh),
          label: const Text('Tekrar Dene'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
          ),
        ),
      ],
    ),
  );

  Widget _buildList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _stocks.length,
    itemBuilder: (ctx, i) {
      final stock = _stocks[i];
      final quote = _quotes[stock['symbol']];
      return _buildStockCard(stock, quote);
    },
  );

  Widget _buildStockCard(Map<String, String> stock, _StockQuote? quote) {
    final isPositive = (quote?.changePercent ?? 0) >= 0;
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
                  child: Center(
                    child: Text(
                      stock['logo']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock['symbol']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        stock['name']!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (quote != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${quote.current.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(top: 4),
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
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isPositive ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
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
                  )
                else
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
