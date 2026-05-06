class NearbyRoute {
  final String routeNameAr;
  final String? routeShortNameAr;
  final double? distanceM;

  const NearbyRoute({
    required this.routeNameAr,
    required this.routeShortNameAr,
    required this.distanceM,
  });

  double get distanceMOrInf => distanceM ?? double.infinity;

  int? get distanceMetersRounded => distanceM?.round();
}
