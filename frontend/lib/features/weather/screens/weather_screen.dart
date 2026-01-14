import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

/// Weather Screen - Hava Durumu Ekranı
///
/// Gradient arka planlı, animasyonlu modern hava durumu sayfası.
/// Canlı konum desteği ile.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _service = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  WeatherData? _weather;
  List<ForecastData> _forecast = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentCity = 'İstanbul';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Canlı konum al ve hava durumu getir
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Konum izni kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Konum izni reddedildi');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan açın.',
        );
        return;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Konum servisi kapalı. Lütfen açın.');
        return;
      }

      // Konumu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Koordinatlarla hava durumu al
      setState(() {
        _isLoading = true;
        _isLoadingLocation = false;
      });

      final weather = await _service.getCurrentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weather = weather;
        _currentCity = weather.cityName;
        _isLoading = false;
        _hasError = false;
      });

      // Tahmin için de yükle
      _loadForecast(_currentCity);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Konum bulundu: ${weather.cityName}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showLocationError('Konum alınamadı: $e');
    }
  }

  void _showLocationError(String message) {
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final weather = await _service.getCurrentWeatherByCity(_currentCity);
      final forecast = await _service.getForecast(_currentCity);
      final dailyForecast = _service.getDailyForecast(forecast);

      setState(() {
        _weather = weather;
        _forecast = dailyForecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadForecast(String city) async {
    try {
      final forecast = await _service.getForecast(city);
      final dailyForecast = _service.getDailyForecast(forecast);
      setState(() => _forecast = dailyForecast);
    } catch (e) {
      // Tahmin yüklenemezse sessizce devam et
    }
  }

  void _searchCity(String city) {
    if (city.isEmpty) return;
    setState(() {
      _currentCity = city;
    });
    _loadWeather();
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        'Hava Durumu',
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
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(gradient: _getBackgroundGradient()),
      child: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _buildWeatherContent(),
      ),
    );
  }

  LinearGradient _getBackgroundGradient() {
    if (_weather == null) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4A90D9), Color(0xFF1E3C72)],
      );
    }

    final condition = _weather!.condition.toLowerCase();
    final isNight = _weather!.isNight;

    if (isNight) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      );
    }

    switch (condition) {
      case 'clear':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
        );
      case 'clouds':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)],
        );
      case 'rain':
      case 'drizzle':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF373B44), Color(0xFF4286f4)],
        );
      case 'thunderstorm':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF232526), Color(0xFF414345)],
        );
      case 'snow':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6DADA), Color(0xFF274046)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90D9), Color(0xFF48C6EF)],
        );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Hava durumu yükleniyor...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Hava durumu alınamadı',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    return RefreshIndicator(
      onRefresh: _loadWeather,
      color: Colors.white,
      backgroundColor: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Search Bar
            _buildSearchBar(),

            const SizedBox(height: 24),

            // Weather Emoji & Temp
            _buildMainWeather(),

            const SizedBox(height: 32),

            // Weather Details Card
            _buildDetailsCard(),

            const SizedBox(height: 24),

            // Forecast Section
            _buildForecastSection(),

            // Popular Cities
            _buildPopularCities(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Şehir ara...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onSubmitted: _searchCity,
      ),
    );
  }

  Widget _buildMainWeather() {
    return Column(
      children: [
        // City Name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 20),
            const SizedBox(width: 4),
            Text(
              '${_weather!.cityName}${_weather!.country.isNotEmpty ? ", ${_weather!.country}" : ""}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Weather Emoji
        Text(_weather!.weatherEmoji, style: const TextStyle(fontSize: 100)),

        const SizedBox(height: 16),

        // Temperature
        Text(
          _weather!.temperatureString,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w200,
            height: 1,
          ),
        ),

        const SizedBox(height: 8),

        // Description
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _weather!.descriptionTr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Feels Like
        Text(
          'Hissedilen: ${_weather!.feelsLikeString}',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildDetailItem(
                    Icons.water_drop,
                    'Nem',
                    '${_weather!.humidity}%',
                    Colors.lightBlue,
                  ),
                  _buildDetailItem(
                    Icons.air,
                    'Rüzgar',
                    '${_weather!.windSpeed.round()} km/s',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailItem(
                    Icons.compress,
                    'Basınç',
                    '${_weather!.pressure} hPa',
                    Colors.orange,
                  ),
                  _buildDetailItem(
                    Icons.visibility,
                    'Görüş',
                    '${(_weather!.visibility / 1000).round()} km',
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailItem(
                    Icons.wb_sunny,
                    'Gün Doğumu',
                    '${_weather!.sunrise.hour}:${_weather!.sunrise.minute.toString().padLeft(2, '0')}',
                    Colors.amber,
                  ),
                  _buildDetailItem(
                    Icons.nightlight_round,
                    'Gün Batımı',
                    '${_weather!.sunset.hour}:${_weather!.sunset.minute.toString().padLeft(2, '0')}',
                    Colors.indigo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    if (_forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5 Günlük Tahmin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final forecast = _forecast[index];
              return _buildForecastCard(forecast, index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(ForecastData forecast, bool isToday) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withOpacity(0.25)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isToday ? 'Bugün' : forecast.dayName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getWeatherEmoji(forecast.condition),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '${forecast.temperature.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }

  Widget _buildPopularCities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Popüler Şehirler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PopularCities.turkey.take(8).map((city) {
            final isSelected = city == _currentCity;
            return GestureDetector(
              onTap: () => _searchCity(city),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(isSelected ? 0.5 : 0.2),
                  ),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isSelected ? 1.0 : 0.8),
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
