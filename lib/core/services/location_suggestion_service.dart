import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../di/injection.dart';

class LocationSuggestion {
  final String title;
  final String? subtitle;
  final LatLng position;
  final String? city;
  final String? state;
  final String? pincode;

  LocationSuggestion({
    required this.title,
    this.subtitle,
    required this.position,
    this.city,
    this.state,
    this.pincode,
  });
}

class LocationSuggestionService {
  static const int _maxSuggestions = 10;
  static const int _minQueryLength = 2;
  
  // Using Nominatim (OpenStreetMap) for better autocomplete suggestions in India
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Get location suggestions based on a query string
  /// Returns a list of formatted address suggestions filtered to India only
  static Future<List<LocationSuggestion>> getStreetAreaSuggestions(String query) async {
    if (query.length < _minQueryLength) {
      return [];
    }

    try {
      // 1. Try Nominatim with Biasing (Fastest & most structured)
      List<LocationSuggestion> suggestions = await _searchNominatim(query, biasToNcr: true);
      
      // 2. If no results, try Nominatim without Biasing
      if (suggestions.isEmpty) {
        suggestions = await _searchNominatim(query, biasToNcr: false);
      }
      
      // 3. If still no results, fallback to Native Geocoder (Google/Apple)
      // This is crucial for specific business names like "RAAS Engineers" 
      // which might not be in OpenStreetMap but are in proprietary maps.
      if (suggestions.isEmpty) {
        suggestions = await _searchNativeGeocoder(query);
      }

      return suggestions;
    } catch (e) {
      print('Error fetching location suggestions: $e');
      return [];
    }
  }

  static Future<List<LocationSuggestion>> _searchNominatim(String query, {required bool biasToNcr}) async {
    try {
      final dio = getIt<Dio>();
      const String ncrViewbox = '77.0,28.9,77.7,28.4';
      
      final queryParams = {
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'namedetails': 1,
        'limit': 15,
        'countrycodes': 'in',
        'accept-language': 'en',
      };

      if (biasToNcr) {
        queryParams['viewbox'] = ncrViewbox;
        queryParams['bounded'] = '0';
      }
      
      final response = await dio.get(
        _baseUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'User-Agent': 'FreshVeggieApp/1.0 (contact: support@freshveggie.com)',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        final suggestions = <LocationSuggestion>[];
        final seenTitles = <String>{};

        for (final item in data) {
          if (suggestions.length >= _maxSuggestions) break;

          final address = item['address'] as Map<String, dynamic>?;
          final namedetails = item['namedetails'] as Map<String, dynamic>?;
          
          String title = '';
          if (namedetails != null && namedetails['name'] != null) {
            title = namedetails['name'].toString();
          }
          
          if (title.isEmpty && address != null) {
            final titleKeys = ['building', 'house_name', 'amenity', 'office', 'shop', 'industrial', 'commercial', 'road', 'neighbourhood'];
            for (final key in titleKeys) {
              if (address[key] != null) {
                title = address[key].toString();
                break;
              }
            }
          }
          
          if (title.isEmpty) {
            title = item['display_name'].toString().split(',').first;
          }

          final List<String> subtitleParts = [];
          if (address != null) {
            final subtitleKeys = ['road', 'neighbourhood', 'suburb', 'city', 'town', 'village', 'state_district', 'state', 'postcode'];
            for (final key in subtitleKeys) {
              if (address[key] != null) {
                final val = address[key].toString();
                if (val.toLowerCase() != title.toLowerCase() && !subtitleParts.contains(val)) {
                  subtitleParts.add(val);
                }
              }
            }
          }
          
          String subtitle = subtitleParts.join(', ');
          if (subtitle.isEmpty) {
            final parts = item['display_name'].toString().split(',');
            if (parts.length > 1) {
              subtitle = parts.skip(1).join(',').trim();
            }
          }

          final fullDisplayName = item['display_name'].toString();
          if (seenTitles.contains(fullDisplayName.toLowerCase())) continue;
          seenTitles.add(fullDisplayName.toLowerCase());

          suggestions.add(LocationSuggestion(
            title: title,
            subtitle: subtitle.isNotEmpty ? subtitle : fullDisplayName,
            position: LatLng(
              double.parse(item['lat'].toString()),
              double.parse(item['lon'].toString()),
            ),
            city: address?['city'] ?? address?['town'] ?? address?['village'] ?? address?['municipality'],
            state: address?['state'],
            pincode: address?['postcode'],
          ));
        }
        return suggestions;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<LocationSuggestion>> _searchNativeGeocoder(String query) async {
    try {
      // Append India for better native search
      final searchQuery = query.toLowerCase().contains('india') ? query : '$query, India';
      final locations = await locationFromAddress(searchQuery);
      
      final suggestions = <LocationSuggestion>[];
      final seenCoordinates = <String>{};

      for (final loc in locations) {
        if (suggestions.length >= _maxSuggestions) break;

        final coordKey = '${loc.latitude.toStringAsFixed(4)},${loc.longitude.toStringAsFixed(4)}';
        if (seenCoordinates.contains(coordKey)) continue;
        seenCoordinates.add(coordKey);

        try {
          final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            
            // Only include results from India
            if (pm.country?.toLowerCase().contains('india') == true) {
              final title = pm.name ?? pm.street ?? query;
              final subtitle = [pm.subLocality, pm.locality, pm.administrativeArea, pm.postalCode]
                  .where((s) => s != null && s.isNotEmpty && s != title)
                  .join(', ');

              suggestions.add(LocationSuggestion(
                title: title,
                subtitle: subtitle.isNotEmpty ? subtitle : null,
                position: LatLng(loc.latitude, loc.longitude),
                city: pm.locality,
                state: pm.administrativeArea,
                pincode: pm.postalCode,
              ));
            }
          }
        } catch (_) {}
      }
      return suggestions;
    } catch (_) {}
    return [];
  }

  // Backward compatibility
  static Future<List<LocationSuggestion>> getLocationSuggestions(String query) async {
    return getStreetAreaSuggestions(query);
  }
}
