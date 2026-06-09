import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/usecases/get_location_usecase.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final GetCurrentLocationAddressUseCase getLocationUseCase;
  final SharedPreferences _sharedPreferences;

  static const String _locationStorageKey = 'saved_location';

  LocationCubit({
    required this.getLocationUseCase,
    required SharedPreferences sharedPreferences,
  })  : _sharedPreferences = sharedPreferences,
        super(LocationInitial()) {
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final raw = _sharedPreferences.getString(_locationStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final location = _locationFromJson(decoded);
          if (location.isWithinServiceArea) {
            emit(LocationLoaded(location));
            return;
          } else {
            emit(LocationUnserviceable(location));
            return;
          }
        }
      } catch (e) {
        // If loading fails, fall back to fetching current location
        debugPrint('Error loading saved location: $e');
      }
    }
    // If no saved location or loading failed, fetch current location
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    emit(LocationLoading());
    final result = await getLocationUseCase(NoParams());
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (location) {
        if (location.isWithinServiceArea) {
          emit(LocationLoaded(location));
          _persistLocation(location);
        } else {
          emit(LocationUnserviceable(location));
          _persistLocation(location);
        }
      },
    );
  }

  void updateLocation(LocationEntity location) {
    if (location.isWithinServiceArea) {
      emit(LocationLoaded(location));
    } else {
      emit(LocationUnserviceable(location));
    }
    _persistLocation(location);
  }

  Future<void> _persistLocation(LocationEntity location) async {
    final locationJson = _locationToJson(location);
    await _sharedPreferences.setString(_locationStorageKey, jsonEncode(locationJson));
  }

  Map<String, dynamic> _locationToJson(LocationEntity location) {
    return {
      'address': location.address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'distanceInKm': location.distanceInKm,
      'isWithinServiceArea': location.isWithinServiceArea,
    };
  }

  LocationEntity _locationFromJson(Map<String, dynamic> json) {
    return LocationEntity(
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceInKm: (json['distanceInKm'] as num?)?.toDouble() ?? 0.0,
      isWithinServiceArea: json['isWithinServiceArea'] as bool? ?? false,
    );
  }
}
