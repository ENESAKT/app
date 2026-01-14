import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_keys.dart';

/// AI Models Screen - Hugging Face ile Duygu Analizi
class AiModelsScreen extends StatefulWidget {
  const AiModelsScreen({super.key});
  @override
  State<AiModelsScreen> createState() => _AiModelsScreenState();
}

class _AiModelsScreenState extends State<AiModelsScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _sentiment;
  double? _confidence;
  bool _isLoading = false;
  String? _error;

  final List<String> _examples = [
    'Bu ürün harika, çok beğendim!',
    'Bugün hava çok güzel.',
    'Korkunç bir deneyimdi.',
    'Film fena değildi.',
    'Yemek berbattı, bir daha gelmem.',
    'I love this app, it works perfectly!',
    'This is the worst experience ever.',
    'The weather is nice today.',
  ];

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _sentiment = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://api-inference.huggingface.co/models/cardiffnlp/twitter-roberta-base-sentiment',
        ),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFace}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'inputs': text}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final results = List<Map<String, dynamic>>.from(data[0]);
          results.sort(
            (a, b) => (b['score'] as double).compareTo(a['score'] as double),
          );
          final top = results.first;
          final label = top['label'] as String;
          final score = top['score'] as double;
          String sentiment;
          if (label.contains('POSITIVE') || label == 'LABEL_2')
            sentiment = 'Pozitif 😊';
          else if (label.contains('NEGATIVE') || label == 'LABEL_0')
            sentiment = 'Negatif 😞';
          else
            sentiment = 'Nötr 😐';
          setState(() {
            _sentiment = sentiment;
            _confidence = score;
            _isLoading = false;
          });
        } else {
          throw Exception('Beklenmeyen yanıt formatı');
        }
      } else if (response.statusCode == 503) {
        throw Exception('Model yükleniyor, lütfen tekrar deneyin');
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
          'AI Duygu Analizi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF6B73FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildInputSection(),
                const SizedBox(height: 16),
                _buildExamples(),
                const SizedBox(height: 24),
                if (_sentiment != null || _error != null) _buildResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hugging Face AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'twitter-roberta-base-sentiment',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildInputSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analiz edilecek metin:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Bir cümle yazın...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _analyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 8),
                            Text(
                              'Analiz Et',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Örnek cümleler:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map(
                (e) => GestureDetector(
                  onTap: () => _textController.text = e,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.length > 30 ? '${e.substring(0, 30)}...' : e,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
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
              Text(
                _sentiment!.contains('Pozitif')
                    ? '😊'
                    : _sentiment!.contains('Negatif')
                    ? '😞'
                    : '😐',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                _sentiment!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Güven: ${((_confidence ?? 0) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _confidence ?? 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _sentiment!.contains('Pozitif')
                            ? [Colors.green, Colors.greenAccent]
                            : _sentiment!.contains('Negatif')
                            ? [Colors.red, Colors.redAccent]
                            : [Colors.grey, Colors.grey.shade400],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
