import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/vendor_delivery_service.dart';
import '../datasources/location_remote_datasource.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource dataSource;
  final VendorDeliveryService vendorDeliveryService;

  LocationRepositoryImpl(this.dataSource, this.vendorDeliveryService);

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

        final isWithinServiceArea =
            await vendorDeliveryService.isLocationServiceable(
          position.latitude,
          position.longitude,
        );

        // We still want to calculate minDistance for the entity
        final vendors = await vendorDeliveryService.loadAllVendorMetadata();
        double? minDistance;
        for (final vendor in vendors.values) {
          if (vendor.isBlocked ||
              vendor.latitude == null ||
              vendor.longitude == null) {
            continue;
          }
          final dist = VendorDeliveryService.haversineDistanceKm(
            position.latitude,
            position.longitude,
            vendor.latitude!,
            vendor.longitude!,
          );
          if (minDistance == null || dist < minDistance) {
            minDistance = dist;
          }
        }

        return Right(
          LocationEntity(
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
            distanceInKm: minDistance ?? 0.0,
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

  @override
  Future<Either<Failure, bool>> isLocationServiceable(
      double latitude, double longitude) async {
    try {
      final isServiceable = await vendorDeliveryService.isLocationServiceable(
          latitude, longitude);
      return Right(isServiceable);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
