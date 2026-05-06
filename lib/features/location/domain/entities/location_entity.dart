class LocationEntity {
  final String address;
  final double latitude;
  final double longitude;
  final double distanceInKm;
  final bool isWithinServiceArea;

  const LocationEntity({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceInKm,
    required this.isWithinServiceArea,
  });
}
