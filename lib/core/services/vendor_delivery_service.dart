import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/product/domain/entities/product_entity.dart';

class VendorMetadata {
  const VendorMetadata({
    required this.vendorId,
    required this.storeName,
    required this.latitude,
    required this.longitude,
    required this.deliveryRadiusKm,
    required this.isBlocked,
  });

  final String vendorId;
  final String storeName;
  final double? latitude;
  final double? longitude;
  final double deliveryRadiusKm;
  final bool isBlocked;
}

class VendorDeliveryService {
  VendorDeliveryService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const double defaultDeliveryRadiusKm = 10.0;

  final FirebaseFirestore _firestore;

  Future<Map<String, VendorMetadata>> loadVendorMetadata(
    Set<String> vendorIds,
  ) async {
    final ids = vendorIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) return const {};

    final metadata = <String, VendorMetadata>{};
    final idList = ids.toList(growable: false);

    for (var i = 0; i < idList.length; i += 10) {
      final chunk = idList.sublist(
        i,
        (i + 10) > idList.length ? idList.length : (i + 10),
      );
      final snapshot = await _firestore
          .collection('vendors')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        metadata[doc.id] = VendorMetadata(
          vendorId: doc.id,
          storeName: _readStoreName(data),
          latitude: _asDoubleOrNull(data['latitude']),
          longitude: _asDoubleOrNull(data['longitude']),
          deliveryRadiusKm:
              _asDouble(data['deliveryRadiusKm'], defaultDeliveryRadiusKm),
          isBlocked: _asBool(data['isBlocked']),
        );
      }
    }

    return metadata;
  }

  Future<Map<String, VendorMetadata>> loadAllVendorMetadata() async {
    final snapshot = await _firestore.collection('vendors').get();
    final metadata = <String, VendorMetadata>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      metadata[doc.id] = VendorMetadata(
        vendorId: doc.id,
        storeName: _readStoreName(data),
        latitude: _asDoubleOrNull(data['latitude']),
        longitude: _asDoubleOrNull(data['longitude']),
        deliveryRadiusKm:
            _asDouble(data['deliveryRadiusKm'], defaultDeliveryRadiusKm),
        isBlocked: _asBool(data['isBlocked']),
      );
    }

    return metadata;
  }

  Future<bool> isLocationServiceable(
    double userLatitude,
    double userLongitude,
  ) async {
    debugPrint('--- [DEBUG] Serviceability Check Started ---');
    debugPrint('User Location: Lat: $userLatitude, Lng: $userLongitude');

    final vendorMap = await loadAllVendorMetadata();
    if (vendorMap.isEmpty) {
      debugPrint('[DEBUG] No vendors found in database.');
      return false;
    }

    bool isServiceable = false;
    for (final vendor in vendorMap.values) {
      if (vendor.isBlocked) {
        debugPrint(
            '[DEBUG] Vendor ${vendor.storeName} (${vendor.vendorId}) is blocked. Skipping.');
        continue;
      }
      if (vendor.latitude == null || vendor.longitude == null) {
        debugPrint(
            '[DEBUG] Vendor ${vendor.storeName} (${vendor.vendorId}) has missing coordinates. Skipping.');
        continue;
      }

      final distanceKm = haversineDistanceKm(
        userLatitude,
        userLongitude,
        vendor.latitude!,
        vendor.longitude!,
      );

      debugPrint('[DEBUG] Checking Vendor: ${vendor.storeName}');
      debugPrint(
          '  [DEBUG] Vendor Location: Lat: ${vendor.latitude}, Lng: ${vendor.longitude}');
      debugPrint('  [DEBUG] Delivery Radius: ${vendor.deliveryRadiusKm} km');
      debugPrint('  [DEBUG] Calculated Distance: $distanceKm km');

      if (distanceKm <= vendor.deliveryRadiusKm) {
        debugPrint('  [DEBUG] Result: SERVICEABLE');
        isServiceable = true;
      } else {
        debugPrint('  [DEBUG] Result: OUT OF RANGE');
      }
    }

    debugPrint('[DEBUG] Final Serviceability Result: $isServiceable');
    debugPrint('--- [DEBUG] Serviceability Check Ended ---');
    return isServiceable;
  }

  ProductEntity enrichProduct(
    ProductEntity product,
    VendorMetadata? vendor, {
    double? userLatitude,
    double? userLongitude,
  }) {
    final resolvedVendorId = (product.vendorId).trim();
    final vendorId =
        resolvedVendorId.isNotEmpty ? resolvedVendorId : vendor?.vendorId ?? '';
    final storeName = (product.vendorStoreName).trim().isNotEmpty
        ? product.vendorStoreName
        : (vendor?.storeName ?? '');
    final radiusKm = vendor?.deliveryRadiusKm ?? defaultDeliveryRadiusKm;
    final hasCoords = vendor?.latitude != null && vendor?.longitude != null;

    double? distanceKm;
    bool isDeliverable = true;
    if (userLatitude != null &&
        userLongitude != null &&
        hasCoords &&
        !((vendor?.isBlocked) ?? false)) {
      distanceKm = haversineDistanceKm(
        userLatitude,
        userLongitude,
        vendor!.latitude!,
        vendor.longitude!,
      );
      isDeliverable = distanceKm <= radiusKm;

      debugPrint('[DEBUG] Product: ${product.name}');
      debugPrint('  [DEBUG] Vendor: $storeName ($vendorId)');
      debugPrint(
          '  [DEBUG] User Location: Lat: $userLatitude, Lng: $userLongitude');
      debugPrint(
          '  [DEBUG] Vendor Location: Lat: ${vendor.latitude}, Lng: ${vendor.longitude}');
      debugPrint('  [DEBUG] Delivery Radius: $radiusKm km');
      debugPrint('  [DEBUG] Calculated Distance: $distanceKm km');
      debugPrint('  [DEBUG] Serviceable: $isDeliverable');
    } else if ((vendor?.isBlocked) ?? false) {
      isDeliverable = false;
      debugPrint(
          '[DEBUG] Product ${product.name}: Vendor $vendorId is BLOCKED');
    } else if (userLatitude != null && userLongitude != null && !hasCoords) {
      debugPrint(
          '[DEBUG] Product ${product.name}: Vendor $vendorId missing coordinates');
      isDeliverable = false;
    }

    return product.copyWith(
      vendorId: vendorId,
      vendorStoreName: storeName,
      vendorDeliveryRadiusKm: radiusKm,
      vendorDistanceKm: distanceKm,
      isVendorBlocked: vendor?.isBlocked ?? false,
      isDeliverableToUser: isDeliverable,
    );
  }

  List<ProductEntity> enrichAndFilterProducts(
    List<ProductEntity> products, {
    required Map<String, VendorMetadata> vendorMap,
    double? userLatitude,
    double? userLongitude,
  }) {
    final enriched = products
        .map(
          (product) => enrichProduct(
            product,
            vendorMap[product.vendorId],
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          ),
        )
        .toList(growable: false);

    if (userLatitude == null || userLongitude == null) {
      return enriched.where((p) => !p.isVendorBlocked).toList(growable: false);
    }

    return enriched
        .where((p) => p.isDeliverableToUser && !p.isVendorBlocked)
        .toList(growable: false);
  }

  static double haversineDistanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLat)) *
            math.cos(_toRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * (math.pi / 180);

  static String _readStoreName(Map<String, dynamic> data) {
    final storeName = (data['storeName'] as String?)?.trim() ?? '';
    if (storeName.isNotEmpty) return storeName;
    return (data['vendorStoreName'] as String?)?.trim() ?? '';
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
