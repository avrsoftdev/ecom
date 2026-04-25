import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'checkout_state.dart';
import '../../domain/entities/checkout_contact_entity.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required SharedPreferences sharedPreferences,
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _sharedPreferences = sharedPreferences,
        _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(CheckoutInitial());

  static const _savedContactsKey = 'checkout_saved_contacts';

  final SharedPreferences _sharedPreferences;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  void startCheckout() {
    emit(CheckoutContactStep(CheckoutContactEntity.empty()));
    _loadSavedContacts();
  }

  void updateContact(CheckoutContactEntity contact) {
    emit(CheckoutContactStep(contact, savedContacts: _savedContacts));
  }

  void setOrderForSelf(String name, String address) {
    emit(CheckoutContactStep(CheckoutContactEntity(
      name: name,
      houseFlatBuilding: '',
      streetAreaColony: address,
      city: '',
      state: '',
      pincode: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: true,
    ), savedContacts: _savedContacts));
  }

  void setOrderForSomeoneElse() {
    emit(CheckoutContactStep(const CheckoutContactEntity(
      name: '',
      houseFlatBuilding: '',
      streetAreaColony: '',
      city: '',
      state: '',
      pincode: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: false,
    ), savedContacts: _savedContacts));
  }

  void useSavedContact(CheckoutContactEntity contact) {
    emit(CheckoutContactStep(contact, savedContacts: _savedContacts));
  }

  Future<void> saveContactForLater(CheckoutContactEntity contact) async {
    if (!_hasUsefulDetails(contact)) return;

    final updatedContacts = _dedupeContacts([contact, ..._savedContacts]);
    _savedContacts = updatedContacts.take(5).toList();
    await _sharedPreferences.setString(
      _savedContactsKey,
      jsonEncode(_savedContacts.map((contact) => contact.toJson()).toList()),
    );

    final current = state;
    if (current is CheckoutContactStep) {
      emit(CheckoutContactStep(
        current.contact,
        savedContacts: _savedContacts,
      ));
    }
  }

  List<CheckoutContactEntity> _savedContacts = const [];

  Future<void> _loadSavedContacts() async {
    final localContacts = _loadLocalSavedContacts();
    final orderContacts = await _loadOrderContacts();
    _savedContacts = _dedupeContacts([...localContacts, ...orderContacts])
        .take(5)
        .toList();

    final current = state;
    if (current is CheckoutContactStep) {
      emit(CheckoutContactStep(
        current.contact,
        savedContacts: _savedContacts,
      ));
    }
  }

  List<CheckoutContactEntity> _loadLocalSavedContacts() {
    final raw = _sharedPreferences.getString(_savedContactsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_contactFromJson)
          .where(_hasUsefulDetails)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CheckoutContactEntity>> _loadOrderContacts() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const [];

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .limit(10)
          .get();

      final orders = snapshot.docs.toList()
        ..sort((a, b) {
          final aCreated = a.data()['createdAt'];
          final bCreated = b.data()['createdAt'];
          if (aCreated is Timestamp && bCreated is Timestamp) {
            return bCreated.compareTo(aCreated);
          }
          return 0;
        });

      return orders
          .map((doc) => _contactFromOrder(doc.data()))
          .whereType<CheckoutContactEntity>()
          .where(_hasUsefulDetails)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  CheckoutContactEntity? _contactFromOrder(Map<String, dynamic> order) {
    final structured = order['checkoutContact'];
    if (structured is Map<String, dynamic>) {
      return _contactFromJson(structured);
    }

    final address = order['shippingAddress'] as String?;
    if (address == null || address.trim().isEmpty) return null;

    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return CheckoutContactEntity(
      name: (order['customerName'] as String?) ?? '',
      houseFlatBuilding: parts.isNotEmpty ? parts.first : '',
      streetAreaColony: parts.length > 1 ? parts[1] : address,
      landmark: parts.length > 2 ? parts[2] : '',
      city: parts.length > 3 ? parts[3] : '',
      state: parts.length > 4 ? parts[4] : '',
      pincode: parts.length > 5 ? parts[5] : '',
      phoneNumber: (order['phone'] as String?) ?? '',
      isForSelf: true,
    );
  }

  CheckoutContactEntity _contactFromJson(Map<String, dynamic> json) {
    return CheckoutContactEntity(
      name: (json['name'] as String?) ?? '',
      houseFlatBuilding: (json['houseFlatBuilding'] as String?) ?? '',
      streetAreaColony: (json['streetAreaColony'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      pincode: (json['pincode'] as String?) ?? '',
      landmark: (json['landmark'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      isForSelf: (json['isForSelf'] as bool?) ?? true,
    );
  }

  List<CheckoutContactEntity> _dedupeContacts(
    List<CheckoutContactEntity> contacts,
  ) {
    final seen = <String>{};
    final result = <CheckoutContactEntity>[];

    for (final contact in contacts) {
      final key = [
        contact.name,
        contact.houseFlatBuilding,
        contact.streetAreaColony,
        contact.city,
        contact.state,
        contact.pincode,
        contact.phoneNumber,
      ].join('|').toLowerCase();

      if (seen.add(key)) {
        result.add(contact);
      }
    }

    return result;
  }

  bool _hasUsefulDetails(CheckoutContactEntity contact) {
    return contact.name.trim().isNotEmpty ||
        contact.houseFlatBuilding.trim().isNotEmpty ||
        contact.streetAreaColony.trim().isNotEmpty ||
        contact.phoneNumber.trim().isNotEmpty;
  }
}
