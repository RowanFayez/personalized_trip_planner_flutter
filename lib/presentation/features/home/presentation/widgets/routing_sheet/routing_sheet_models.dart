/// Data models used across routing-sheet widgets.
class RoutingFirstConnectionInfo {
  final String originName;
  final int distanceMeters;

  const RoutingFirstConnectionInfo({
    required this.originName,
    required this.distanceMeters,
  });
}

class RoutingFinalConnectionInfo {
  final String destinationName;
  final int distanceMeters;

  const RoutingFinalConnectionInfo({
    required this.destinationName,
    required this.distanceMeters,
  });
}
