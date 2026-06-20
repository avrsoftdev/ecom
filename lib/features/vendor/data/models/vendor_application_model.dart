import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/vendor_application_entity.dart';

class VendorApplicationModel extends VendorApplicationEntity {
  const VendorApplicationModel({
    required super.id,
    required super.userId,
    required super.storeName,
    required super.ownerName,
    required super.mobileNumber,
    required super.email,
    required super.businessType,
    super.yearsInBusiness,
    super.shopAddress,
    super.landmark,
    super.city,
    super.state,
    super.pinCode,
    super.latitude,
    super.longitude,
    super.aadhaarUrl,
    super.panUrl,
    super.gstNumber,
    super.gstCertificateUrl,
    super.fssaiNumber,
    super.fssaiCertificateUrl,
    super.bankAccountHolderName,
    super.bankName,
    super.bankAccountNumber,
    super.bankIfscCode,
    super.upiId,
    super.storeOpeningTime,
    super.storeClosingTime,
    super.weeklyOffDays,
    super.emergencyContactNumber,
    super.storeLogoUrl,
    super.storeFrontImageUrl,
    super.storeInteriorImageUrl,
    super.isInformationAccurate = false,
    super.agreedToTerms = false,
    super.understoodApprovalProcess = false,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.reviewedBy,
    super.reviewComment,
  });

  factory VendorApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VendorApplicationModel(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      storeName: data['store_name'] as String? ?? '',
      ownerName: data['owner_name'] as String? ?? '',
      mobileNumber: data['mobile_number'] as String? ?? '',
      email: data['email'] as String? ?? '',
      businessType: _businessTypeFromString(data['business_type'] as String?),
      yearsInBusiness: data['years_in_business'] as String?,
      shopAddress: data['shop_address'] as String?,
      landmark: data['landmark'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      pinCode: data['pin_code'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      aadhaarUrl: data['aadhaar_url'] as String?,
      panUrl: data['pan_url'] as String?,
      gstNumber: data['gst_number'] as String?,
      gstCertificateUrl: data['gst_certificate_url'] as String?,
      fssaiNumber: data['fssai_number'] as String?,
      fssaiCertificateUrl: data['fssai_certificate_url'] as String?,
      bankAccountHolderName: data['bank_account_holder_name'] as String?,
      bankName: data['bank_name'] as String?,
      bankAccountNumber: data['bank_account_number'] as String?,
      bankIfscCode: data['bank_ifsc_code'] as String?,
      upiId: data['upi_id'] as String?,
      storeOpeningTime: data['store_opening_time'] as String?,
      storeClosingTime: data['store_closing_time'] as String?,
      weeklyOffDays: (data['weekly_off_days'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      emergencyContactNumber: data['emergency_contact_number'] as String?,
      storeLogoUrl: data['store_logo_url'] as String?,
      storeFrontImageUrl: data['store_front_image_url'] as String?,
      storeInteriorImageUrl: data['store_interior_image_url'] as String?,
      isInformationAccurate: data['is_information_accurate'] as bool? ?? false,
      agreedToTerms: data['agreed_to_terms'] as bool? ?? false,
      understoodApprovalProcess:
          data['understood_approval_process'] as bool? ?? false,
      status: _statusFromString(data['status'] as String?),
      createdAt: _ts(data['created_at']) ?? DateTime.now(),
      updatedAt: _ts(data['updated_at']),
      reviewedBy: data['reviewed_by'] as String?,
      reviewComment: data['review_comment'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'store_name': storeName,
      'owner_name': ownerName,
      'mobile_number': mobileNumber,
      'email': email,
      'business_type': _businessTypeToString(businessType),
      'years_in_business': yearsInBusiness,
      'shop_address': shopAddress,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pin_code': pinCode,
      'latitude': latitude,
      'longitude': longitude,
      'aadhaar_url': aadhaarUrl,
      'pan_url': panUrl,
      'gst_number': gstNumber,
      'gst_certificate_url': gstCertificateUrl,
      'fssai_number': fssaiNumber,
      'fssai_certificate_url': fssaiCertificateUrl,
      'bank_account_holder_name': bankAccountHolderName,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc_code': bankIfscCode,
      'upi_id': upiId,
      'store_opening_time': storeOpeningTime,
      'store_closing_time': storeClosingTime,
      'weekly_off_days': weeklyOffDays,
      'emergency_contact_number': emergencyContactNumber,
      'store_logo_url': storeLogoUrl,
      'store_front_image_url': storeFrontImageUrl,
      'store_interior_image_url': storeInteriorImageUrl,
      'is_information_accurate': isInformationAccurate,
      'agreed_to_terms': agreedToTerms,
      'understood_approval_process': understoodApprovalProcess,
      'status': _statusToString(status),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'reviewed_by': reviewedBy,
      'review_comment': reviewComment,
    };
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static BusinessType _businessTypeFromString(String? value) {
    switch (value) {
      case 'grocery_store':
        return BusinessType.groceryStore;
      case 'supermarket':
        return BusinessType.supermarket;
      case 'dairy':
        return BusinessType.dairy;
      case 'fruits_vegetables':
        return BusinessType.fruitsVegetables;
      case 'bakery':
        return BusinessType.bakery;
      case 'other':
      default:
        return BusinessType.other;
    }
  }

  static String _businessTypeToString(BusinessType type) {
    switch (type) {
      case BusinessType.groceryStore:
        return 'grocery_store';
      case BusinessType.supermarket:
        return 'supermarket';
      case BusinessType.dairy:
        return 'dairy';
      case BusinessType.fruitsVegetables:
        return 'fruits_vegetables';
      case BusinessType.bakery:
        return 'bakery';
      case BusinessType.other:
        return 'other';
    }
  }

  static VendorApplicationStatus _statusFromString(String? value) {
    switch (value) {
      case 'applied':
        return VendorApplicationStatus.applied;
      case 'under_review':
        return VendorApplicationStatus.underReview;
      case 'documents_pending':
        return VendorApplicationStatus.documentsPending;
      case 'approved':
        return VendorApplicationStatus.approved;
      case 'rejected':
        return VendorApplicationStatus.rejected;
      case 'active_vendor':
        return VendorApplicationStatus.activeVendor;
      default:
        return VendorApplicationStatus.applied;
    }
  }

  static String _statusToString(VendorApplicationStatus status) {
    switch (status) {
      case VendorApplicationStatus.applied:
        return 'applied';
      case VendorApplicationStatus.underReview:
        return 'under_review';
      case VendorApplicationStatus.documentsPending:
        return 'documents_pending';
      case VendorApplicationStatus.approved:
        return 'approved';
      case VendorApplicationStatus.rejected:
        return 'rejected';
      case VendorApplicationStatus.activeVendor:
        return 'active_vendor';
    }
  }
}
