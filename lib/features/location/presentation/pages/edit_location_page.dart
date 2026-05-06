import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    _searchController.dispose();
    super.dispose();
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
      final suggestions = <_LocationSuggestion>[];
      final Set<String> seenAddresses = <String>{};
      final Set<String> seenCoordinates = <String>{};
      
      // Try multiple search queries to get comprehensive results
      final searchQueries = <String>[];
      if (!query.contains('India')) {
        searchQueries.add('$query, India');
        searchQueries.add('$query');
        // Add more specific search variations for better diversity
        searchQueries.add('$query, Delhi, India');
        searchQueries.add('$query, Uttar Pradesh, India');
        searchQueries.add('$query, NCR, India');
      } else {
        searchQueries.add(query);
      }
      
      for (final searchQuery in searchQueries) {
        if (suggestions.length >= 5) break; // Stop when we have 5 unique suggestions
        
        try {
          print('=== DEBUG: Searching for: $searchQuery ===');
          final places = await locationFromAddress(searchQuery);
          print('Found ${places.length} places for query: $searchQuery');

          for (final place in places) {
            if (suggestions.length >= 5) break; // Stop when we have 5 unique suggestions
            
            final coordKey = '${place.latitude.toStringAsFixed(4)},${place.longitude.toStringAsFixed(4)}';
            if (seenCoordinates.contains(coordKey)) continue; // Skip duplicate coordinates
            
            try {
              // Try to get placemarks with locale for better results
              final placemarks = await placemarkFromCoordinates(
                place.latitude,
                place.longitude,
              );
              
              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                // Only include suggestions that are in India
                if (placemark.country == 'India' || 
                    placemark.country?.toLowerCase().contains('india') == true) {
                  final formatted = _formatPlacemark(placemark, searchQuery);
                  
                  // Check for duplicate addresses
                  if (!seenAddresses.contains(formatted.toLowerCase())) {
                    seenAddresses.add(formatted.toLowerCase());
                    seenCoordinates.add(coordKey);
                    suggestions.add(_LocationSuggestion(
                      title: formatted,
                      position: LatLng(place.latitude, place.longitude),
                    ));
                    print('Added suggestion: $formatted');
                  }
                }
              }
            } catch (_) {
              try {
                // Fallback: try without locale
                final placemarks = await placemarkFromCoordinates(
                  place.latitude,
                  place.longitude,
                );
                
                if (placemarks.isNotEmpty) {
                  final placemark = placemarks.first;
                  // Only include suggestions that are in India
                  if (placemark.country == 'India' || 
                      placemark.country?.toLowerCase().contains('india') == true) {
                    final formatted = _formatPlacemark(placemark, searchQuery);
                    
                    // Check for duplicate addresses
                    if (!seenAddresses.contains(formatted.toLowerCase())) {
                      seenAddresses.add(formatted.toLowerCase());
                      seenCoordinates.add(coordKey);
                      suggestions.add(_LocationSuggestion(
                        title: formatted,
                        position: LatLng(place.latitude, place.longitude),
                      ));
                      print('Added fallback suggestion: $formatted');
                    }
                  }
                }
              } catch (_) {
                // For coordinates without placemarks, check if they're roughly in India
                if (_isInIndiaBounds(place.latitude, place.longitude)) {
                  final coordTitle = '${place.latitude.toStringAsFixed(6)}, ${place.longitude.toStringAsFixed(6)}';
                  
                  // Check for duplicate coordinates
                  if (!seenAddresses.contains(coordTitle.toLowerCase())) {
                    seenAddresses.add(coordTitle.toLowerCase());
                    seenCoordinates.add(coordKey);
                    suggestions.add(_LocationSuggestion(
                      title: coordTitle,
                      position: LatLng(place.latitude, place.longitude),
                    ));
                    print('Added coordinate suggestion: $coordTitle');
                  }
                }
              }
            }
          }
        } catch (_) {
          print('Error searching for query: $searchQuery');
        }
      }

      setState(() {
        _suggestions
          ..clear()
          ..addAll(suggestions);
      });
      print('Final suggestions count: ${suggestions.length}');
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

  // Helper method to check if coordinates are within India bounds
  bool _isInIndiaBounds(double latitude, double longitude) {
    // India approximate bounds: 6.7°N to 37.1°N, 68.7°E to 97.3°E
    return latitude >= 6.7 && latitude <= 37.1 && 
           longitude >= 68.7 && longitude <= 97.3;
  }

  String _formatPlacemark(Placemark placemark, [String? originalQuery]) {
    // Debug: Print all available placemark data
    print('=== DEBUG: Placemark Data ===');
    print('name: ${placemark.name}');
    print('street: ${placemark.street}');
    print('thoroughfare: ${placemark.thoroughfare}');
    print('subThoroughfare: ${placemark.subThoroughfare}');
    print('subLocality: ${placemark.subLocality}');
    print('locality: ${placemark.locality}');
    print('subAdministrativeArea: ${placemark.subAdministrativeArea}');
    print('administrativeArea: ${placemark.administrativeArea}');
    print('postalCode: ${placemark.postalCode}');
    print('country: ${placemark.country}');
    print('originalQuery: $originalQuery');
    print('========================');
    
    final components = <String>[];
    
    // If we have an original query and it's not already in the placemark name, add it first
    if (originalQuery != null && 
        originalQuery.isNotEmpty && 
        placemark.name?.toLowerCase().contains(originalQuery.toLowerCase()) != true) {
      components.add(originalQuery);
    }
    
    // Add name/establishment if available
    if (placemark.name?.isNotEmpty == true && 
        !components.contains(placemark.name!)) {
      components.add(placemark.name!);
    }
    
    // Add thoroughfare (street name)
    if (placemark.thoroughfare?.isNotEmpty == true) {
      components.add(placemark.thoroughfare!);
    }
    
    // Add sub-thoroughfare (street number)
    if (placemark.subThoroughfare?.isNotEmpty == true) {
      components.add(placemark.subThoroughfare!);
    }
    
    // Add street if different from thoroughfare
    if (placemark.street?.isNotEmpty == true && 
        placemark.street != placemark.thoroughfare &&
        !components.contains(placemark.street!)) {
      components.add(placemark.street!);
    }
    
    // Add sub-locality (neighborhood, area)
    if (placemark.subLocality?.isNotEmpty == true) {
      components.add(placemark.subLocality!);
    }
    
    // Add locality (city/town)
    if (placemark.locality?.isNotEmpty == true) {
      components.add(placemark.locality!);
    }
    
    // Add sub-administrative area (district)
    if (placemark.subAdministrativeArea?.isNotEmpty == true) {
      components.add(placemark.subAdministrativeArea!);
    }
    
    // Add administrative area (state)
    if (placemark.administrativeArea?.isNotEmpty == true) {
      components.add(placemark.administrativeArea!);
    }
    
    // Add postal code
    if (placemark.postalCode?.isNotEmpty == true) {
      components.add(placemark.postalCode!);
    }
    
    // Add country
    if (placemark.country?.isNotEmpty == true) {
      components.add(placemark.country!);
    }
    
    final fullAddress = components.join(', ');
    print('Final formatted address: $fullAddress');
    print('========================');
    
    return fullAddress;
  }

  Future<void> _updateSelectedLocation(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _selectedAddress = null;
    });

    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _selectedAddress = _formatPlacemark(placemarks.first);
        });
      }
    } catch (_) {
      setState(() {
        _selectedAddress = '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
      });
    }
  }

  void _saveLocation() {
    if (_selectedLatLng == null || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a location on the map or from search suggestions.')),
      );
      return;
    }

    final locationEntity = LocationEntity(
      address: _selectedAddress!,
      latitude: _selectedLatLng!.latitude,
      longitude: _selectedLatLng!.longitude,
      distanceInKm: 0.0,
      isWithinServiceArea: true,
    );

    context.read<LocationCubit>().updateLocation(locationEntity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLatLng ?? const LatLng(28.6139, 77.2090);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Location'),
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
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
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
                  constraints: BoxConstraints(maxHeight: 200.h),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(height: 1.h),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                        title: Text(
                          suggestion.title,
                          style: TextStyle(fontSize: 14.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _searchController.text = suggestion.title;
                          _suggestions.clear();
                          _mapController.move(suggestion.position, 14);
                          _updateSelectedLocation(suggestion.position);
                        },
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
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    _selectedAddress ?? 'Tap the map or choose a suggestion to select a location.',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
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
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
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
