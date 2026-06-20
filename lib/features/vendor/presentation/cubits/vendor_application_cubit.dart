import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/vendor_application_entity.dart';
import '../../domain/repositories/vendor_repository.dart';

part 'vendor_application_state.dart';

class VendorApplicationCubit extends Cubit<VendorApplicationState> {
  VendorApplicationCubit(this.repository)
      : super(const VendorApplicationState()) {
    _loadExistingApplication();
  }

  final VendorRepository repository;
  final _storage = FirebaseStorage.instance;

  Future<void> _loadExistingApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final result = await repository.getVendorApplicationByUserId(user.uid);
    result.fold(
      (l) => null,
      (application) {
        if (application != null) {
          emit(state.copyWith(existingApplication: application));
        }
      },
    );
  }

  void updateStoreName(String value) =>
      emit(state.copyWith(storeName: value));
  void updateOwnerName(String value) =>
      emit(state.copyWith(ownerName: value));
  void updateMobileNumber(String value) =>
      emit(state.copyWith(mobileNumber: value));
  void updateEmail(String value) =>
      emit(state.copyWith(email: value));
  void updateBusinessType(BusinessType value) =>
      emit(state.copyWith(businessType: value));
  void updateYearsInBusiness(String? value) =>
      emit(state.copyWith(yearsInBusiness: value));
  void updateShopAddress(String? value) =>
      emit(state.copyWith(shopAddress: value));
  void updateLandmark(String? value) =>
      emit(state.copyWith(landmark: value));
  void updateCity(String? value) =>
      emit(state.copyWith(city: value));
  void updateState(String? value) =>
      emit(state.copyWith(state: value));
  void updatePinCode(String? value) =>
      emit(state.copyWith(pinCode: value));
  void updateLocation(double? lat, double? lng) =>
      emit(state.copyWith(latitude: lat, longitude: lng));
  void updateAadhaarImage(XFile? file) =>
      emit(state.copyWith(aadhaarImage: file));
  void updatePanImage(XFile? file) =>
      emit(state.copyWith(panImage: file));
  void updateGstNumber(String? value) =>
      emit(state.copyWith(gstNumber: value));
  void updateGstCertificateImage(XFile? file) =>
      emit(state.copyWith(gstCertificateImage: file));
  void updateFssaiNumber(String? value) =>
      emit(state.copyWith(fssaiNumber: value));
  void updateFssaiCertificateImage(XFile? file) =>
      emit(state.copyWith(fssaiCertificateImage: file));
  void updateBankAccountHolderName(String? value) =>
      emit(state.copyWith(bankAccountHolderName: value));
  void updateBankName(String? value) =>
      emit(state.copyWith(bankName: value));
  void updateBankAccountNumber(String? value) =>
      emit(state.copyWith(bankAccountNumber: value));
  void updateBankIfscCode(String? value) =>
      emit(state.copyWith(bankIfscCode: value));
  void updateUpiId(String? value) =>
      emit(state.copyWith(upiId: value));
  void updateStoreOpeningTime(String? value) =>
      emit(state.copyWith(storeOpeningTime: value));
  void updateStoreClosingTime(String? value) =>
      emit(state.copyWith(storeClosingTime: value));
  void updateWeeklyOffDays(List<String>? value) =>
      emit(state.copyWith(weeklyOffDays: value));
  void updateEmergencyContactNumber(String? value) =>
      emit(state.copyWith(emergencyContactNumber: value));
  void updateStoreLogoImage(XFile? file) =>
      emit(state.copyWith(storeLogoImage: file));
  void updateStoreFrontImage(XFile? file) =>
      emit(state.copyWith(storeFrontImage: file));
  void updateStoreInteriorImage(XFile? file) =>
      emit(state.copyWith(storeInteriorImage: file));
  void updateIsInformationAccurate(bool value) =>
      emit(state.copyWith(isInformationAccurate: value));
  void updateAgreedToTerms(bool value) =>
      emit(state.copyWith(agreedToTerms: value));
  void updateUnderstoodApprovalProcess(bool value) =>
      emit(state.copyWith(understoodApprovalProcess: value));

  Future<String?> _uploadFile(XFile file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = kIsWeb
        ? ref.putData(await file.readAsBytes())
        : ref.putFile(Uri.file(file.path).toFilePath() as dynamic);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> submitApplication() async {
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userId = user.uid;
      final applicationId =
          state.existingApplication?.id ?? FirebaseFirestore.instance.collection('vendor_applications').doc().id;

      // Upload images
      String? aadhaarUrl = state.existingApplication?.aadhaarUrl;
      String? panUrl = state.existingApplication?.panUrl;
      String? gstCertificateUrl = state.existingApplication?.gstCertificateUrl;
      String? fssaiCertificateUrl = state.existingApplication?.fssaiCertificateUrl;
      String? storeLogoUrl = state.existingApplication?.storeLogoUrl;
      String? storeFrontImageUrl = state.existingApplication?.storeFrontImageUrl;
      String? storeInteriorImageUrl = state.existingApplication?.storeInteriorImageUrl;

      if (state.aadhaarImage != null) {
        aadhaarUrl = await _uploadFile(
            state.aadhaarImage!, 'vendor_applications/$applicationId/aadhaar.${state.aadhaarImage!.name.split('.').last}');
      }
      if (state.panImage != null) {
        panUrl = await _uploadFile(
            state.panImage!, 'vendor_applications/$applicationId/pan.${state.panImage!.name.split('.').last}');
      }
      if (state.gstCertificateImage != null) {
        gstCertificateUrl = await _uploadFile(
            state.gstCertificateImage!, 'vendor_applications/$applicationId/gst_certificate.${state.gstCertificateImage!.name.split('.').last}');
      }
      if (state.fssaiCertificateImage != null) {
        fssaiCertificateUrl = await _uploadFile(
            state.fssaiCertificateImage!, 'vendor_applications/$applicationId/fssai_certificate.${state.fssaiCertificateImage!.name.split('.').last}');
      }
      if (state.storeLogoImage != null) {
        storeLogoUrl = await _uploadFile(
            state.storeLogoImage!, 'vendor_applications/$applicationId/store_logo.${state.storeLogoImage!.name.split('.').last}');
      }
      if (state.storeFrontImage != null) {
        storeFrontImageUrl = await _uploadFile(
            state.storeFrontImage!, 'vendor_applications/$applicationId/store_front.${state.storeFrontImage!.name.split('.').last}');
      }
      if (state.storeInteriorImage != null) {
        storeInteriorImageUrl = await _uploadFile(
            state.storeInteriorImage!, 'vendor_applications/$applicationId/store_interior.${state.storeInteriorImage!.name.split('.').last}');
      }

      final application = VendorApplicationEntity(
        id: applicationId,
        userId: userId,
        storeName: state.storeName,
        ownerName: state.ownerName,
        mobileNumber: state.mobileNumber,
        email: state.email,
        businessType: state.businessType,
        yearsInBusiness: state.yearsInBusiness,
        shopAddress: state.shopAddress,
        landmark: state.landmark,
        city: state.city,
        state: state.state,
        pinCode: state.pinCode,
        latitude: state.latitude,
        longitude: state.longitude,
        aadhaarUrl: aadhaarUrl,
        panUrl: panUrl,
        gstNumber: state.gstNumber,
        gstCertificateUrl: gstCertificateUrl,
        fssaiNumber: state.fssaiNumber,
        fssaiCertificateUrl: fssaiCertificateUrl,
        bankAccountHolderName: state.bankAccountHolderName,
        bankName: state.bankName,
        bankAccountNumber: state.bankAccountNumber,
        bankIfscCode: state.bankIfscCode,
        upiId: state.upiId,
        storeOpeningTime: state.storeOpeningTime,
        storeClosingTime: state.storeClosingTime,
        weeklyOffDays: state.weeklyOffDays,
        emergencyContactNumber: state.emergencyContactNumber,
        storeLogoUrl: storeLogoUrl,
        storeFrontImageUrl: storeFrontImageUrl,
        storeInteriorImageUrl: storeInteriorImageUrl,
        isInformationAccurate: state.isInformationAccurate,
        agreedToTerms: state.agreedToTerms,
        understoodApprovalProcess: state.understoodApprovalProcess,
        status: VendorApplicationStatus.applied,
        createdAt: state.existingApplication?.createdAt ?? DateTime.now(),
      );

      final result = await repository.createVendorApplication(application);
      result.fold(
        (failure) => emit(state.copyWith(
          isSubmitting: false,
          error: failure.message,
        )),
        (_) => emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          existingApplication: application,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }
}
