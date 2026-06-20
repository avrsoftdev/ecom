part of 'vendor_application_cubit.dart';

class VendorApplicationState {
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
  final XFile? aadhaarImage;
  final XFile? panImage;
  final String? gstNumber;
  final XFile? gstCertificateImage;
  final String? fssaiNumber;
  final XFile? fssaiCertificateImage;
  final String? bankAccountHolderName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfscCode;
  final String? upiId;
  final String? storeOpeningTime;
  final String? storeClosingTime;
  final List<String>? weeklyOffDays;
  final String? emergencyContactNumber;
  final XFile? storeLogoImage;
  final XFile? storeFrontImage;
  final XFile? storeInteriorImage;
  final bool isInformationAccurate;
  final bool agreedToTerms;
  final bool understoodApprovalProcess;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;
  final VendorApplicationEntity? existingApplication;

  const VendorApplicationState({
    this.storeName = '',
    this.ownerName = '',
    this.mobileNumber = '',
    this.email = '',
    this.businessType = BusinessType.other,
    this.yearsInBusiness,
    this.shopAddress,
    this.landmark,
    this.city,
    this.state,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.aadhaarImage,
    this.panImage,
    this.gstNumber,
    this.gstCertificateImage,
    this.fssaiNumber,
    this.fssaiCertificateImage,
    this.bankAccountHolderName,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.upiId,
    this.storeOpeningTime,
    this.storeClosingTime,
    this.weeklyOffDays,
    this.emergencyContactNumber,
    this.storeLogoImage,
    this.storeFrontImage,
    this.storeInteriorImage,
    this.isInformationAccurate = false,
    this.agreedToTerms = false,
    this.understoodApprovalProcess = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
    this.existingApplication,
  });

  VendorApplicationState copyWith({
    String? storeName,
    String? ownerName,
    String? mobileNumber,
    String? email,
    BusinessType? businessType,
    String? yearsInBusiness,
    String? shopAddress,
    String? landmark,
    String? city,
    String? state,
    String? pinCode,
    double? latitude,
    double? longitude,
    XFile? aadhaarImage,
    XFile? panImage,
    String? gstNumber,
    XFile? gstCertificateImage,
    String? fssaiNumber,
    XFile? fssaiCertificateImage,
    String? bankAccountHolderName,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfscCode,
    String? upiId,
    String? storeOpeningTime,
    String? storeClosingTime,
    List<String>? weeklyOffDays,
    String? emergencyContactNumber,
    XFile? storeLogoImage,
    XFile? storeFrontImage,
    XFile? storeInteriorImage,
    bool? isInformationAccurate,
    bool? agreedToTerms,
    bool? understoodApprovalProcess,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    VendorApplicationEntity? existingApplication,
  }) {
    return VendorApplicationState(
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      businessType: businessType ?? this.businessType,
      yearsInBusiness: yearsInBusiness ?? this.yearsInBusiness,
      shopAddress: shopAddress ?? this.shopAddress,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      aadhaarImage: aadhaarImage ?? this.aadhaarImage,
      panImage: panImage ?? this.panImage,
      gstNumber: gstNumber ?? this.gstNumber,
      gstCertificateImage: gstCertificateImage ?? this.gstCertificateImage,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
      fssaiCertificateImage: fssaiCertificateImage ?? this.fssaiCertificateImage,
      bankAccountHolderName: bankAccountHolderName ?? this.bankAccountHolderName,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      upiId: upiId ?? this.upiId,
      storeOpeningTime: storeOpeningTime ?? this.storeOpeningTime,
      storeClosingTime: storeClosingTime ?? this.storeClosingTime,
      weeklyOffDays: weeklyOffDays ?? this.weeklyOffDays,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      storeLogoImage: storeLogoImage ?? this.storeLogoImage,
      storeFrontImage: storeFrontImage ?? this.storeFrontImage,
      storeInteriorImage: storeInteriorImage ?? this.storeInteriorImage,
      isInformationAccurate: isInformationAccurate ?? this.isInformationAccurate,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      understoodApprovalProcess: understoodApprovalProcess ?? this.understoodApprovalProcess,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      existingApplication: existingApplication ?? this.existingApplication,
    );
  }
}
