import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/location_suggestion_service.dart';
import '../cubits/location_cubit.dart';
import '../cubits/location_state.dart';
import '../../domain/entities/location_entity.dart';

class EditLocationPage extends StatefulWidget {
  const EditLocationPage({super.key});

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final List<_LocationSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchControllerChanged);
    final locationState = context.read<LocationCubit>().state;
    if (locationState is LocationLoaded) {
      final location = locationState.location;
      _selectedLatLng = LatLng(location.latitude, location.longitude);
      _selectedAddress = location.address;
    } else if (locationState is LocationUnserviceable) {
      final location = locationState.location;
      _selectedLatLng = LatLng(location.latitude, location.longitude);
      _selectedAddress = location.address;
    } else {
      _selectedLatLng = const LatLng(28.6139, 77.2090);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedLatLng != null) {
        _mapController.move(_selectedLatLng!, 13);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchControllerChanged() {
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _suggestions.clear();
      _isSearching = false;
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocations(query.trim());
    });
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final suggestions =
          await LocationSuggestionService.getStreetAreaSuggestions(query);

      setState(() {
        _suggestions
          ..clear()
          ..addAll(suggestions.map((s) => _LocationSuggestion(
                title:
                    s.subtitle != null ? '${s.title}, ${s.subtitle}' : s.title,
                position: s.position,
              )));
      });
    } catch (_) {
      setState(() {
        _suggestions.clear();
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSuggestion(_LocationSuggestion suggestion) {
    _searchController.text = suggestion.title;
    _suggestions.clear();
    _mapController.move(suggestion.position, 14);
    _updateSelectedLocation(suggestion.position, suggestion.title);
  }

  // Calculate distance from Wave City, Ghaziabad using Haversine formula
  double _calculateDistanceFromWaveCity(double latitude, double longitude) {
    const double waveCityLat = 28.6535345;
    const double waveCityLng = 77.4996625;

    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1Rad = _degreesToRadians(waveCityLat);
    double lat2Rad = _degreesToRadians(latitude);
    double deltaLatRad = _degreesToRadians(latitude - waveCityLat);
    double deltaLngRad = _degreesToRadians(longitude - waveCityLng);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _formatPlacemark(Placemark placemark) {
    final components = <String>[];

    // Add name/establishment if available
    if (placemark.name?.isNotEmpty == true) {
      components.add(placemark.name!);
    }

    // Add thoroughfare (street name)
    if (placemark.thoroughfare?.isNotEmpty == true) {
      components.add(placemark.thoroughfare!);
    }

    // Add sub-locality (neighborhood, area)
    if (placemark.subLocality?.isNotEmpty == true) {
      components.add(placemark.subLocality!);
    }

    // Add locality (city/town)
    if (placemark.locality?.isNotEmpty == true) {
      components.add(placemark.locality!);
    }

    // Add administrative area (state)
    if (placemark.administrativeArea?.isNotEmpty == true) {
      components.add(placemark.administrativeArea!);
    }

    // Add country
    if (placemark.country?.isNotEmpty == true) {
      components.add(placemark.country!);
    }

    return components.join(', ');
  }

  Future<void> _updateSelectedLocation(LatLng latLng, [String? address]) async {
    setState(() {
      _selectedLatLng = latLng;
      if (address != null) {
        _selectedAddress = address;
      } else {
        _selectedAddress = null;
      }
    });

    // Only fetch placemarks if no address was provided
    if (address == null) {
      try {
        final placemarks =
            await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          setState(() {
            _selectedAddress = _formatPlacemark(placemarks.first);
          });
        }
      } catch (_) {
        setState(() {
          _selectedAddress =
              '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
        });
      }
    }
  }

  void _saveLocation() {
    if (_selectedLatLng == null || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please choose a location on the map or from search suggestions.')),
      );
      return;
    }

    // Check if location is within 10km of Wave City, Ghaziabad
    final distanceFromWaveCity = _calculateDistanceFromWaveCity(
      _selectedLatLng!.latitude,
      _selectedLatLng!.longitude,
    );

    if (distanceFromWaveCity > 10.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We are not currently available in your area'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final locationEntity = LocationEntity(
      address: _selectedAddress!,
      latitude: _selectedLatLng!.latitude,
      longitude: _selectedLatLng!.longitude,
      distanceInKm: distanceFromWaveCity,
      isWithinServiceArea: true,
    );

    context.read<LocationCubit>().updateLocation(locationEntity);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLatLng ?? const LatLng(28.6139, 77.2090);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Location', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF006400),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search location',
                  hintText: 'Enter address, city, or landmark',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (_searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Clear location',
                              onPressed: _clearSearch,
                            )
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            if (_suggestions.isNotEmpty)
              Flexible(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(maxHeight: 300.h),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(height: 1.h),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 6.h),
                        title: Text(
                          suggestion.title,
                          style: TextStyle(fontSize: 14.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: center,
                    zoom: 13,
                    onTap: (_, latLng) {
                      _updateSelectedLocation(latLng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.freshveggie',
                    ),
                    if (_selectedLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 60,
                            height: 60,
                            point: _selectedLatLng!,
                            builder: (context) => const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected location',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _selectedAddress ??
                        'Tap the map or choose a suggestion to select a location.',
                    style:
                        TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006400),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Save location',
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSuggestion {
  final String title;
  final LatLng position;

  _LocationSuggestion({required this.title, required this.position});
}
