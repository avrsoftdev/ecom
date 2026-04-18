import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

abstract class LocationRemoteDataSource {
  Future<Position> getCurrentPosition();
  Future<List<Placemark>> getPlacemarks(Position position);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  @override
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Future<List<Placemark>> getPlacemarks(Position position) async {
    return await placemarkFromCoordinates(position.latitude, position.longitude);
  }
}
