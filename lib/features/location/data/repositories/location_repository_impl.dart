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
        // Constructing a readable address
        final address =
            '${place.subLocality ?? place.locality}, ${place.administrativeArea}';
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
