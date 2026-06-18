import 'package:equatable/equatable.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';

class TripSegmentModel extends Equatable {
  final int index;
  final String? mode;
  final String? name;
  final double? fareEgp;
  final String startedAt;
  final String? endedAt;
  final String confidence;
  final int pointCount;

  const TripSegmentModel({
    required this.index,
    required this.startedAt,
    this.mode,
    this.name,
    this.fareEgp,
    this.endedAt,
    this.confidence = SegmentConfidence.unknown,
    this.pointCount = 0,
  });

  factory TripSegmentModel.fromMap(Map<dynamic, dynamic> map) {
    final mode = _readString(map['mode']);
    return TripSegmentModel(
      index: _readInt(map['index']),
      mode: mode,
      name: _readString(map['name']),
      fareEgp: _readNullableDouble(map['fare_egp']),
      startedAt:
          _readString(map['started_at']) ?? DateTime.now().toIso8601String(),
      endedAt: _readString(map['ended_at']),
      confidence:
          _readString(map['confidence']) ??
          (mode == null
              ? SegmentConfidence.unknown
              : SegmentConfidence.userConfirmed),
      pointCount: _readInt(map['point_count']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'index': index,
      'mode': mode,
      'name': name,
      'fare_egp': fareEgp,
      'started_at': startedAt,
      'ended_at': endedAt,
      'confidence': confidence,
      'point_count': pointCount,
    };
  }

  TripSegmentModel copyWith({
    int? index,
    String? mode,
    bool clearMode = false,
    String? name,
    bool clearName = false,
    double? fareEgp,
    bool clearFare = false,
    String? startedAt,
    String? endedAt,
    bool clearEndedAt = false,
    String? confidence,
    int? pointCount,
  }) {
    final nextMode = clearMode ? null : mode ?? this.mode;
    return TripSegmentModel(
      index: index ?? this.index,
      mode: nextMode,
      name: clearName ? null : name ?? this.name,
      fareEgp: clearFare ? null : fareEgp ?? this.fareEgp,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      confidence:
          confidence ??
          (nextMode == null
              ? SegmentConfidence.unknown
              : SegmentConfidence.userConfirmed),
      pointCount: pointCount ?? this.pointCount,
    );
  }

  static String? _readString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _readNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  List<Object?> get props => <Object?>[
    index,
    mode,
    name,
    fareEgp,
    startedAt,
    endedAt,
    confidence,
    pointCount,
  ];
}
