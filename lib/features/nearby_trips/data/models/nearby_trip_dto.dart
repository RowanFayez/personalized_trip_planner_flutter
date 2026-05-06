class NearbyTripDto {
  final String tripId;
  final String? routeNameAr;
  final String? routeShortNameAr;
  final double? distanceM;

  const NearbyTripDto({
    required this.tripId,
    required this.routeNameAr,
    required this.routeShortNameAr,
    required this.distanceM,
  });

  factory NearbyTripDto.fromJson(Map<String, dynamic> json) {
    return NearbyTripDto(
      tripId: (json['trip_id'] as String?) ?? '',
      routeNameAr: json['route_name_ar'] as String?,
      routeShortNameAr: json['route_short_name_ar'] as String?,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
    );
  }
}
