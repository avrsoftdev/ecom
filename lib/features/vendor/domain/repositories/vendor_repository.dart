import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vendor_application_entity.dart';

abstract class VendorRepository {
  Future<Either<Failure, void>> createVendorApplication(
      VendorApplicationEntity application);
  Future<Either<Failure, VendorApplicationEntity?>>
      getVendorApplicationByUserId(String userId);
  Stream<List<VendorApplicationEntity>> watchAllVendorApplications({
    String? status,
  });
  Future<Either<Failure, void>> updateVendorApplicationStatus({
    required String applicationId,
    required String status,
    String? reviewedBy,
    String? reviewComment,
  });
  Future<Either<Failure, void>> updateVendorApplication(
      VendorApplicationEntity application);
}
