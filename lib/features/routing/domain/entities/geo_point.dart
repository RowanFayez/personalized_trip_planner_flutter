import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  final double lat;
  final double lon;

  const GeoPoint({required this.lat, required this.lon});

  @override
  List<Object?> get props => [lat, lon];
}
