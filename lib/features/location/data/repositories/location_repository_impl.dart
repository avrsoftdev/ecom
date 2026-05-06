import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/failures.dart';
import '../datasources/location_remote_datasource.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource dataSource;

  LocationRepositoryImpl(this.dataSource);

  static const double _serviceCenterLatitude = 28.6533844;
  static const double _serviceCenterLongitude = 77.4971739;
  static const double _serviceRadiusKm = 10.0;

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocationAddress() async {
    try {
      final position = await dataSource.getCurrentPosition();
      final placemarks = await dataSource.getPlacemarks(position);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.name,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
        ].where((part) => part != null && part.isNotEmpty).toSet().toList();

        final address = parts.join(', ');
        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _serviceCenterLatitude,
          _serviceCenterLongitude,
        );
        final distanceInKm = distanceMeters / 1000.0;
        final isWithinServiceArea = distanceInKm <= _serviceRadiusKm;

        return Right(
          LocationEntity(
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
            distanceInKm: distanceInKm,
            isWithinServiceArea: isWithinServiceArea,
          ),
        );
      } else {
        return const Left(
            ServerFailure('Could not find address for current location.'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
