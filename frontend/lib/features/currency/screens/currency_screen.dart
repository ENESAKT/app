import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_keys.dart';

/// Currency Screen - ExchangeRate-API ile Döviz Çevirici
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '100',
  );
  String _fromCurrency = 'USD';
  String _toCurrency = 'TRY';
  double? _result;
  double? _rate;
  bool _isLoading = false;
  Map<String, double> _rates = {};

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'ABD Doları', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'İngiliz Sterlini', 'flag': '🇬🇧'},
    {'code': 'TRY', 'name': 'Türk Lirası', 'flag': '🇹🇷'},
    {'code': 'JPY', 'name': 'Japon Yeni', 'flag': '🇯🇵'},
    {'code': 'CHF', 'name': 'İsviçre Frangı', 'flag': '🇨🇭'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://v6.exchangerate-api.com/v6/${ApiKeys.exchangeRate}/latest/$_fromCurrency',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = Map<String, dynamic>.from(data['conversion_rates']);
          _rates = rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
          _convert();
        } else {
          throw Exception('API yanıtı başarısız');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kur yüklenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  void _convert() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_rates.containsKey(_toCurrency)) {
      setState(() {
        _rate = _rates[_toCurrency];
        _result = amount * (_rate ?? 1);
      });
    }
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _loadRates();
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
          'Döviz Çevirici',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1ABC9C), Color(0xFF16A085), Color(0xFF2ECC71)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildConverterCard(),
                const SizedBox(height: 24),
                _buildResultCard(),
                const SizedBox(height: 24),
                _buildQuickRates(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConverterCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildCurrencySelector('Kaynak', _fromCurrency, (v) {
                setState(() => _fromCurrency = v!);
                _loadRates();
              }),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _amountController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onChanged: (_) => _convert(),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _swap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    color: Color(0xFF1ABC9C),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCurrencySelector('Hedef', _toCurrency, (v) {
                setState(() => _toCurrency = v!);
                _convert();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    final c = _currencies.firstWhere(
      (x) => x['code'] == value,
      orElse: () => {'code': value, 'name': value, 'flag': '🏳️'},
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(c['flag']!, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF16A085),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  items: _currencies
                      .map(
                        (x) => DropdownMenuItem(
                          value: x['code'],
                          child: Text('${x['flag']} ${x['code']}'),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                Text(
                  '${_amountController.text.isEmpty ? '0' : _amountController.text} $_fromCurrency =',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_result?.toStringAsFixed(2) ?? '-'} $_toCurrency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '1 $_fromCurrency = ${_rate?.toStringAsFixed(4) ?? '-'} $_toCurrency',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRates() {
    if (_rates.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popüler Kurlar (1 $_fromCurrency)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._currencies
            .where(
              (c) =>
                  c['code'] != _fromCurrency && _rates.containsKey(c['code']),
            )
            .take(4)
            .map((c) {
              final rate = _rates[c['code']]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c['code']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      rate.toStringAsFixed(4),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
      ],
    );
  }
}
