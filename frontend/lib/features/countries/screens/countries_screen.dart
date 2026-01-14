import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/countries_service.dart';

/// Countries Screen - Ülkeler Ekranı
///
/// REST Countries API ile tüm dünya ülkelerini listeler.
class CountriesScreen extends StatefulWidget {
  const CountriesScreen({super.key});

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> {
  final CountriesService _service = CountriesService();
  final TextEditingController _searchController = TextEditingController();

  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  bool _isLoading = true;
  String? _error;
  String _selectedRegion = 'Tümü';

  final List<String> _regions = [
    'Tümü',
    'Africa',
    'Americas',
    'Asia',
    'Europe',
    'Oceania',
  ];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final countries = await _service.getAllCountries();
      countries.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _countries = countries;
        _filteredCountries = countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = _countries.where((country) {
        final matchesSearch =
            country.name.toLowerCase().contains(query.toLowerCase()) ||
            (country.capital?.toLowerCase().contains(query.toLowerCase()) ??
                false);
        final matchesRegion =
            _selectedRegion == 'Tümü' || country.region == _selectedRegion;
        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
    });
    _filterCountries(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E44AD), Color(0xFF3498DB), Color(0xFF9B59B6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                    ? _buildErrorState()
                    : _buildCountriesList(),
              ),
            ],
          ),
        ),
      ),
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
        'Dünya Ülkeleri',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${_filteredCountries.length} ülke',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ülke veya başkent ara...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _filterCountries,
            ),
          ),
          const SizedBox(height: 12),

          // Region filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = _selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _selectRegion(region),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        region == 'Tümü'
                            ? '🌍 Tümü'
                            : _getRegionEmoji(region) + ' ' + region,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF8E44AD)
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getRegionEmoji(String region) {
    switch (region) {
      case 'Africa':
        return '🌍';
      case 'Americas':
        return '🌎';
      case 'Asia':
        return '🌏';
      case 'Europe':
        return '🇪🇺';
      case 'Oceania':
        return '🏝️';
      default:
        return '🌐';
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
            'Ülkeler yükleniyor...',
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
            const Icon(Icons.public_off, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ülkeler yüklenemedi',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCountries,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8E44AD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCountries.length,
      itemBuilder: (context, index) =>
          _buildCountryCard(_filteredCountries[index]),
    );
  }

  Widget _buildCountryCard(Country country) {
    return GestureDetector(
      onTap: () => _showCountryDetails(country),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Flag
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        country.flag ?? '🏳️',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Country info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
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
                            Icon(
                              Icons.location_city,
                              color: Colors.white.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                country.capital ?? 'Bilinmiyor',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryDetails(Country country) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flag and name
                    Center(
                      child: Column(
                        children: [
                          Text(
                            country.flag ?? '🏳️',
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            country.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (country.officialName != null)
                            Text(
                              country.officialName!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Details
                    _buildDetailRow(
                      'Başkent',
                      country.capital ?? 'Bilinmiyor',
                      Icons.location_city,
                    ),
                    _buildDetailRow(
                      'Bölge',
                      '${country.region ?? ""} ${country.subregion != null ? "- ${country.subregion}" : ""}',
                      Icons.public,
                    ),
                    _buildDetailRow(
                      'Nüfus',
                      _formatNumber(country.population),
                      Icons.people,
                    ),
                    _buildDetailRow(
                      'Alan',
                      '${_formatNumber(country.area?.toInt())} km²',
                      Icons.square_foot,
                    ),
                    if (country.languages != null)
                      _buildDetailRow(
                        'Diller',
                        country.languages!.values.join(', '),
                        Icons.translate,
                      ),
                    if (country.currencies != null)
                      _buildDetailRow(
                        'Para Birimi',
                        country.currencies!.values.join(', '),
                        Icons.monetization_on,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
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
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(num? number) {
    if (number == null) return 'Bilinmiyor';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
