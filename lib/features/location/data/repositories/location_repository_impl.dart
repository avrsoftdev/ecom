import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/location_remote_datasource.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource dataSource;

  LocationRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, String>> getCurrentLocationAddress() async {
    try {
      final position = await dataSource.getCurrentPosition();
      final placemarks = await dataSource.getPlacemarks(position);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Constructing a detailed address
        final parts = [
          place.name,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
        ].where((part) => part != null && part.isNotEmpty).toSet().toList();

        final address = parts.join(', ');
        return Right(address);
      } else {
        return const Left(
            ServerFailure('Could not find address for current location.'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
