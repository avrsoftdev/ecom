import 'package:equatable/equatable.dart';

enum VendorApplicationStatus {
  applied,
  underReview,
  documentsPending,
  approved,
  rejected,
  activeVendor,
}

enum BusinessType {
  groceryStore,
  supermarket,
  dairy,
  fruitsVegetables,
  bakery,
  other,
}

class VendorApplicationEntity extends Equatable {
  const VendorApplicationEntity({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.ownerName,
    required this.mobileNumber,
    required this.email,
    required this.businessType,
    this.yearsInBusiness,
    this.shopAddress,
    this.landmark,
    this.city,
    this.state,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.aadhaarUrl,
    this.panUrl,
    this.gstNumber,
    this.gstCertificateUrl,
    this.fssaiNumber,
    this.fssaiCertificateUrl,
    this.bankAccountHolderName,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.upiId,
    this.storeOpeningTime,
    this.storeClosingTime,
    this.weeklyOffDays,
    this.emergencyContactNumber,
    this.storeLogoUrl,
    this.storeFrontImageUrl,
    this.storeInteriorImageUrl,
    this.isInformationAccurate = false,
    this.agreedToTerms = false,
    this.understoodApprovalProcess = false,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewComment,
  });

  final String id;
  final String userId;
  final String storeName;
  final String ownerName;
  final String mobileNumber;
  final String email;
  final BusinessType businessType;
  final String? yearsInBusiness;
  final String? shopAddress;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pinCode;
  final double? latitude;
  final double? longitude;
  final String? aadhaarUrl;
  final String? panUrl;
  final String? gstNumber;
  final String? gstCertificateUrl;
  final String? fssaiNumber;
  final String? fssaiCertificateUrl;
  final String? bankAccountHolderName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfscCode;
  final String? upiId;
  final String? storeOpeningTime;
  final String? storeClosingTime;
  final List<String>? weeklyOffDays;
  final String? emergencyContactNumber;
  final String? storeLogoUrl;
  final String? storeFrontImageUrl;
  final String? storeInteriorImageUrl;
  final bool isInformationAccurate;
  final bool agreedToTerms;
  final bool understoodApprovalProcess;
  final VendorApplicationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reviewedBy;
  final String? reviewComment;

  @override
  List<Object?> get props => [
        id,
        userId,
        storeName,
        ownerName,
        mobileNumber,
        email,
        businessType,
        yearsInBusiness,
        shopAddress,
        landmark,
        city,
        state,
        pinCode,
        latitude,
        longitude,
        aadhaarUrl,
        panUrl,
        gstNumber,
        gstCertificateUrl,
        fssaiNumber,
        fssaiCertificateUrl,
        bankAccountHolderName,
        bankName,
        bankAccountNumber,
        bankIfscCode,
        upiId,
        storeOpeningTime,
        storeClosingTime,
        weeklyOffDays,
        emergencyContactNumber,
        storeLogoUrl,
        storeFrontImageUrl,
        storeInteriorImageUrl,
        isInformationAccurate,
        agreedToTerms,
        understoodApprovalProcess,
        status,
        createdAt,
        updatedAt,
        reviewedBy,
        reviewComment,
      ];
}
