import 'package:equatable/equatable.dart';

import 'potential_transfer_model.dart';
import 'trip_segment_model.dart';

class TripMetadataModel extends Equatable {
  final String tripId;
  final String status;
  final String startedAt;
  final String? endedAt;
  final List<TripSegmentModel> segments;
  final List<PotentialTransferModel> potentialTransfers;
  final String? gpxFilePath;
  final double? totalDistanceM;
  final int uploadAttemptCount;
  final String? contributionId;
  final String? lastUploadedAt;
  final int currentSegmentIndex;
  final String? routeName;

  const TripMetadataModel({
    required this.tripId,
    required this.status,
    required this.startedAt,
    required this.segments,
    this.endedAt,
    this.potentialTransfers = const <PotentialTransferModel>[],
    this.gpxFilePath,
    this.totalDistanceM,
    this.uploadAttemptCount = 0,
    this.contributionId,
    this.lastUploadedAt,
    this.currentSegmentIndex = 0,
    this.routeName,
  });

  factory TripMetadataModel.fromMap(Map<dynamic, dynamic> map) {
    return TripMetadataModel(
      tripId: _readString(map['trip_id']) ?? '',
      status: _readString(map['status']) ?? '',
      startedAt:
          _readString(map['started_at']) ?? DateTime.now().toIso8601String(),
      endedAt: _readString(map['ended_at']),
      segments: _readMaps(
        map['segments'],
      ).map(TripSegmentModel.fromMap).toList(growable: false),
      potentialTransfers: _readMaps(
        map['potential_transfers'],
      ).map(PotentialTransferModel.fromMap).toList(growable: false),
      gpxFilePath: _readString(map['gpx_file_path']),
      totalDistanceM: _readNullableDouble(map['total_distance_m']),
      uploadAttemptCount: _readInt(map['upload_attempt_count']),
      contributionId: _readString(map['contribution_id']),
      lastUploadedAt: _readString(map['last_uploaded_at']),
      currentSegmentIndex: _readInt(map['current_segment_index']),
      routeName: _readString(map['route_name']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'trip_id': tripId,
      'status': status,
      'started_at': startedAt,
      'ended_at': endedAt,
      'segments': segments.map((segment) => segment.toMap()).toList(),
      'potential_transfers': potentialTransfers
          .map((transfer) => transfer.toMap())
          .toList(),
      'gpx_file_path': gpxFilePath,
      'total_distance_m': totalDistanceM,
      'upload_attempt_count': uploadAttemptCount,
      'contribution_id': contributionId,
      'last_uploaded_at': lastUploadedAt,
      'current_segment_index': currentSegmentIndex,
      'route_name': routeName,
    };
  }

  TripMetadataModel copyWith({
    String? tripId,
    String? status,
    String? startedAt,
    String? endedAt,
    bool clearEndedAt = false,
    List<TripSegmentModel>? segments,
    List<PotentialTransferModel>? potentialTransfers,
    String? gpxFilePath,
    bool clearGpxFilePath = false,
    double? totalDistanceM,
    bool clearTotalDistance = false,
    int? uploadAttemptCount,
    String? contributionId,
    bool clearContributionId = false,
    String? lastUploadedAt,
    bool clearLastUploadedAt = false,
    int? currentSegmentIndex,
    String? routeName,
    bool clearRouteName = false,
  }) {
    return TripMetadataModel(
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      segments: segments ?? this.segments,
      potentialTransfers: potentialTransfers ?? this.potentialTransfers,
      gpxFilePath: clearGpxFilePath ? null : gpxFilePath ?? this.gpxFilePath,
      totalDistanceM: clearTotalDistance
          ? null
          : totalDistanceM ?? this.totalDistanceM,
      uploadAttemptCount: uploadAttemptCount ?? this.uploadAttemptCount,
      contributionId: clearContributionId
          ? null
          : contributionId ?? this.contributionId,
      lastUploadedAt: clearLastUploadedAt
          ? null
          : lastUploadedAt ?? this.lastUploadedAt,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      routeName: clearRouteName ? null : routeName ?? this.routeName,
    );
  }

  static List<Map<dynamic, dynamic>> _readMaps(Object? value) {
    if (value is! Iterable) return const <Map<dynamic, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<dynamic, dynamic>.from(item))
        .toList(growable: false);
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
    tripId,
    status,
    startedAt,
    endedAt,
    segments,
    potentialTransfers,
    gpxFilePath,
    totalDistanceM,
    uploadAttemptCount,
    contributionId,
    lastUploadedAt,
    currentSegmentIndex,
    routeName,
  ];
}
