import 'package:equatable/equatable.dart';

class GpsPointModel extends Equatable {
  final double lat;
  final double lon;
  final double? altitude;
  final int timestampMs;
  final int segmentIndex;
  final double? accuracyM;
  final double? speedMs;

  const GpsPointModel({
    required this.lat,
    required this.lon,
    required this.timestampMs,
    required this.segmentIndex,
    this.altitude,
    this.accuracyM,
    this.speedMs,
  });

  factory GpsPointModel.fromMap(Map<dynamic, dynamic> map) {
    return GpsPointModel(
      lat: _readDouble(map['lat']),
      lon: _readDouble(map['lon']),
      altitude: _readNullableDouble(map['alt']),
      timestampMs: _readInt(map['ts']),
      segmentIndex: _readInt(map['seg']),
      accuracyM: _readNullableDouble(map['acc']),
      speedMs: _readNullableDouble(map['spd']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lat': lat,
      'lon': lon,
      'alt': altitude,
      'ts': timestampMs,
      'seg': segmentIndex,
      'acc': accuracyM,
      'spd': speedMs,
    };
  }

  GpsPointModel copyWith({
    double? lat,
    double? lon,
    double? altitude,
    int? timestampMs,
    int? segmentIndex,
    double? accuracyM,
    double? speedMs,
  }) {
    return GpsPointModel(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      altitude: altitude ?? this.altitude,
      timestampMs: timestampMs ?? this.timestampMs,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      accuracyM: accuracyM ?? this.accuracyM,
      speedMs: speedMs ?? this.speedMs,
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _readNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  List<Object?> get props => <Object?>[
    lat,
    lon,
    altitude,
    timestampMs,
    segmentIndex,
    accuracyM,
    speedMs,
  ];
}
