import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/vendor_firestore_datasource.dart';
import '../models/vendor_application_model.dart';
import '../../domain/entities/vendor_application_entity.dart';
import '../../domain/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  VendorRepositoryImpl(this.dataSource);

  final VendorFirestoreDataSource dataSource;

  @override
  Future<Either<Failure, void>> createVendorApplication(
      VendorApplicationEntity application) async {
    try {
      final model = VendorApplicationModel(
        id: application.id,
        userId: application.userId,
        storeName: application.storeName,
        ownerName: application.ownerName,
        mobileNumber: application.mobileNumber,
        email: application.email,
        businessType: application.businessType,
        yearsInBusiness: application.yearsInBusiness,
        shopAddress: application.shopAddress,
        landmark: application.landmark,
        city: application.city,
        state: application.state,
        pinCode: application.pinCode,
        latitude: application.latitude,
        longitude: application.longitude,
        aadhaarUrl: application.aadhaarUrl,
        panUrl: application.panUrl,
        gstNumber: application.gstNumber,
        gstCertificateUrl: application.gstCertificateUrl,
        fssaiNumber: application.fssaiNumber,
        fssaiCertificateUrl: application.fssaiCertificateUrl,
        bankAccountHolderName: application.bankAccountHolderName,
        bankName: application.bankName,
        bankAccountNumber: application.bankAccountNumber,
        bankIfscCode: application.bankIfscCode,
        upiId: application.upiId,
        storeOpeningTime: application.storeOpeningTime,
        storeClosingTime: application.storeClosingTime,
        weeklyOffDays: application.weeklyOffDays,
        emergencyContactNumber: application.emergencyContactNumber,
        storeLogoUrl: application.storeLogoUrl,
        storeFrontImageUrl: application.storeFrontImageUrl,
        storeInteriorImageUrl: application.storeInteriorImageUrl,
        isInformationAccurate: application.isInformationAccurate,
        agreedToTerms: application.agreedToTerms,
        understoodApprovalProcess: application.understoodApprovalProcess,
        status: application.status,
        createdAt: application.createdAt,
        updatedAt: application.updatedAt,
        reviewedBy: application.reviewedBy,
        reviewComment: application.reviewComment,
      );
      await dataSource.createVendorApplication(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorApplicationEntity?>>
      getVendorApplicationByUserId(String userId) async {
    try {
      final model = await dataSource.getVendorApplicationByUserId(userId);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<VendorApplicationEntity>> watchAllVendorApplications({
    String? status,
  }) {
    return dataSource.watchAllVendorApplications(status: status).map(
          (list) => list.map((model) => model as VendorApplicationEntity).toList(),
        );
  }

  @override
  Future<Either<Failure, void>> updateVendorApplicationStatus({
    required String applicationId,
    required String status,
    String? reviewedBy,
    String? reviewComment,
  }) async {
    try {
      await dataSource.updateVendorApplicationStatus(
        applicationId: applicationId,
        status: status,
        reviewedBy: reviewedBy,
        reviewComment: reviewComment,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateVendorApplication(
      VendorApplicationEntity application) async {
    try {
      final model = VendorApplicationModel(
        id: application.id,
        userId: application.userId,
        storeName: application.storeName,
        ownerName: application.ownerName,
        mobileNumber: application.mobileNumber,
        email: application.email,
        businessType: application.businessType,
        yearsInBusiness: application.yearsInBusiness,
        shopAddress: application.shopAddress,
        landmark: application.landmark,
        city: application.city,
        state: application.state,
        pinCode: application.pinCode,
        latitude: application.latitude,
        longitude: application.longitude,
        aadhaarUrl: application.aadhaarUrl,
        panUrl: application.panUrl,
        gstNumber: application.gstNumber,
        gstCertificateUrl: application.gstCertificateUrl,
        fssaiNumber: application.fssaiNumber,
        fssaiCertificateUrl: application.fssaiCertificateUrl,
        bankAccountHolderName: application.bankAccountHolderName,
        bankName: application.bankName,
        bankAccountNumber: application.bankAccountNumber,
        bankIfscCode: application.bankIfscCode,
        upiId: application.upiId,
        storeOpeningTime: application.storeOpeningTime,
        storeClosingTime: application.storeClosingTime,
        weeklyOffDays: application.weeklyOffDays,
        emergencyContactNumber: application.emergencyContactNumber,
        storeLogoUrl: application.storeLogoUrl,
        storeFrontImageUrl: application.storeFrontImageUrl,
        storeInteriorImageUrl: application.storeInteriorImageUrl,
        isInformationAccurate: application.isInformationAccurate,
        agreedToTerms: application.agreedToTerms,
        understoodApprovalProcess: application.understoodApprovalProcess,
        status: application.status,
        createdAt: application.createdAt,
        updatedAt: application.updatedAt,
        reviewedBy: application.reviewedBy,
        reviewComment: application.reviewComment,
      );
      await dataSource.updateVendorApplication(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
