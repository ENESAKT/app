import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/api_keys.dart';

/// Maps Screen - Harita Ekranı
/// Geoapify + flutter_map ile interaktif harita.
class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(41.0082, 28.9784); // İstanbul
  double _zoom = 12.0;
  bool _isLoading = false;
  String _locationName = 'İstanbul, Türkiye';

  final List<Map<String, dynamic>> _popularLocations = [
    {'name': 'İstanbul', 'lat': 41.0082, 'lng': 28.9784, 'icon': '🏛️'},
    {'name': 'Ankara', 'lat': 39.9334, 'lng': 32.8597, 'icon': '🏢'},
    {'name': 'İzmir', 'lat': 38.4237, 'lng': 27.1428, 'icon': '🌊'},
    {'name': 'Antalya', 'lat': 36.8969, 'lng': 30.7133, 'icon': '🏖️'},
    {'name': 'Bursa', 'lat': 40.1827, 'lng': 29.0669, 'icon': '🏔️'},
    {'name': 'Paris', 'lat': 48.8566, 'lng': 2.3522, 'icon': '🗼'},
    {'name': 'London', 'lat': 51.5074, 'lng': -0.1278, 'icon': '🎡'},
    {'name': 'New York', 'lat': 40.7128, 'lng': -74.0060, 'icon': '🗽'},
  ];

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi');
        }
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _locationName = 'Mevcut Konum';
        _isLoading = false;
      });
      _mapController.move(_center, 15);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToLocation(Map<String, dynamic> location) {
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    setState(() {
      _center = LatLng(lat, lng);
      _locationName = location['name'];
    });
    _mapController.move(_center, 13);
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
              color: Colors.black54,
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Haritalar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
            onPressed: _isLoading ? null : _getCurrentLocation,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // FLUTTER MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              onPositionChanged: (pos, _) {
                if (pos.zoom != null) _zoom = pos.zoom!;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${ApiKeys.geoapify}',
                userAgentPackageName: 'com.example.frontend',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Bottom Sheet - Location Info
          Positioned(left: 0, right: 0, bottom: 0, child: _buildLocationInfo()),
          // Location Chips
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + 60,
            child: _buildLocationChips(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            backgroundColor: Colors.white,
            onPressed: () {
              _mapController.move(_center, _zoom + 1);
            },
            child: const Icon(Icons.add, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            backgroundColor: Colors.white,
            onPressed: () {
              _mapController.move(_center, _zoom - 1);
            },
            child: const Icon(Icons.remove, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _popularLocations.length,
        itemBuilder: (context, index) {
          final loc = _popularLocations[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _goToLocation(loc),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc['icon'], style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      loc['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationInfo() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _locationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
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
