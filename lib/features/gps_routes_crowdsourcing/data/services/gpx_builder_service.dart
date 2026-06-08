import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../models/gps_point_model.dart';
import '../models/trip_metadata_model.dart';

class GpxBuilderService {
  Future<String> buildGpxFile({
    required TripMetadataModel tripMeta,
    required List<GpsPointModel> rawPoints,
  }) async {
    final xml = await compute<Map<String, dynamic>, String>(
      assembleGpxXml,
      <String, dynamic>{
        'tripMeta': tripMeta.toMap(),
        'rawPoints': rawPoints.map((point) => point.toMap()).toList(),
      },
    );

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final outputDirectory = Directory(
      '${documentsDirectory.path}/${CrowdsourcingGpx.folderName}',
    );
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final file = File('${outputDirectory.path}/${tripMeta.tripId}.gpx');
    await file.writeAsString(xml, flush: true);
    return file.path;
  }
}

String assembleGpxXml(Map<String, dynamic> input) {
  final tripMeta = TripMetadataModel.fromMap(
    Map<dynamic, dynamic>.from(input['tripMeta'] as Map),
  );
  final points = (input['rawPoints'] as List<dynamic>)
      .whereType<Map>()
      .map((item) => GpsPointModel.fromMap(item))
      .where(_isAllowedGpxPoint)
      .toList(growable: false);

  final pointsBySegment = <int, List<GpsPointModel>>{};
  for (final point in points) {
    pointsBySegment.putIfAbsent(point.segmentIndex, () => <GpsPointModel>[]);
    pointsBySegment[point.segmentIndex]!.add(point);
  }

  final startedAt = DateTime.tryParse(tripMeta.startedAt);
  final endedAt = tripMeta.endedAt == null
      ? null
      : DateTime.tryParse(tripMeta.endedAt!);
  final privacyWindow = Duration(
    minutes: CrowdsourcingLimits.privacyFuzzingMinutes,
  );

  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<gpx version="1.1" creator="${_xml(CrowdsourcingGpx.creator)}" '
      'xmlns="${_xml(CrowdsourcingGpx.namespace)}" '
      'xmlns:ns="${_xml(CrowdsourcingGpx.extensionNamespace)}">',
    )
    ..writeln('  <metadata>')
    ..writeln('    <name>NextStation Contribution</name>')
    ..writeln('    <time>${_utcIso(DateTime.now())}</time>')
    ..writeln('    <extensions>')
    ..writeln('      <ns:trip_id>${_xml(tripMeta.tripId)}</ns:trip_id>')
    ..writeln(
      '      <ns:app_version>${_xml(CrowdsourcingGpx.appVersion)}</ns:app_version>',
    )
    ..writeln(
      '      <ns:device_os>${_xml(CrowdsourcingGpx.deviceOs)}</ns:device_os>',
    )
    ..writeln('      <ns:fuzzing_applied>true</ns:fuzzing_applied>')
    ..writeln('      <ns:potential_transfers>');

  for (final transfer in tripMeta.potentialTransfers) {
    buffer
      ..writeln('        <ns:transfer>')
      ..writeln(
        '          <ns:detected_at>${_xml(transfer.detectedAt)}</ns:detected_at>',
      )
      ..writeln(
        '          <ns:boarded_at>${_xml(transfer.boardedAt ?? '')}</ns:boarded_at>',
      )
      ..writeln(
        '          <ns:user_response>${_xml(transfer.userResponse ?? TransferResponses.ignored)}</ns:user_response>',
      )
      ..writeln(
        '          <ns:resulted_in_segment_split>${transfer.resultedInSegmentSplit}</ns:resulted_in_segment_split>',
      )
      ..writeln('        </ns:transfer>');
  }

  buffer
    ..writeln('      </ns:potential_transfers>')
    ..writeln('    </extensions>')
    ..writeln('  </metadata>');

  for (final segment in tripMeta.segments) {
    final segmentPoints =
        pointsBySegment[segment.index] ?? const <GpsPointModel>[];
    if (segmentPoints.isEmpty) continue;

    buffer
      ..writeln('  <trk>')
      ..writeln('    <name>Segment ${segment.index + 1}</name>')
      ..writeln('    <extensions>')
      ..writeln('      <ns:segment_index>${segment.index}</ns:segment_index>')
      ..writeln(
        '      <ns:transit_mode>${_xml(segment.mode ?? 'unknown')}</ns:transit_mode>',
      )
      ..writeln(
        '      <ns:fare_egp>${segment.fareEgp?.toStringAsFixed(2) ?? ''}</ns:fare_egp>',
      )
      ..writeln(
        '      <ns:confidence>${_xml(segment.confidence)}</ns:confidence>',
      )
      ..writeln('    </extensions>')
      ..writeln('    <trkseg>');

    for (final point in segmentPoints) {
      final pointAt = DateTime.fromMillisecondsSinceEpoch(
        point.timestampMs,
        isUtc: false,
      );
      final shouldFuzz = _shouldFuzzPoint(
        pointAt: pointAt,
        startedAt: startedAt,
        endedAt: endedAt,
        privacyWindow: privacyWindow,
      );
      final lat = shouldFuzz ? _fuzzCoordinate(point.lat) : point.lat;
      final lon = shouldFuzz ? _fuzzCoordinate(point.lon) : point.lon;

      buffer.writeln(
        '      <trkpt lat="${lat.toStringAsFixed(6)}" '
        'lon="${lon.toStringAsFixed(6)}">',
      );
      if (point.altitude != null) {
        buffer.writeln(
          '        <ele>${point.altitude!.toStringAsFixed(1)}</ele>',
        );
      }
      buffer
        ..writeln('        <time>${_utcIso(pointAt)}</time>')
        ..writeln('        <extensions>');
      if (point.accuracyM != null) {
        buffer.writeln(
          '          <ns:accuracy>${point.accuracyM!.toStringAsFixed(1)}</ns:accuracy>',
        );
      }
      buffer
        ..writeln('          <ns:fuzzed>$shouldFuzz</ns:fuzzed>')
        ..writeln('        </extensions>')
        ..writeln('      </trkpt>');
    }

    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>');
  }

  buffer.writeln('</gpx>');
  return buffer.toString();
}

bool _isAllowedGpxPoint(GpsPointModel point) {
  final accuracy = point.accuracyM;
  if (accuracy != null && accuracy > CrowdsourcingLimits.gpxAccuracyMaxM) {
    return false;
  }
  final speed = point.speedMs;
  if (speed == 0 &&
      accuracy != null &&
      accuracy > CrowdsourcingLimits.gpxStillAccuracyMaxM) {
    return false;
  }
  return true;
}

bool _shouldFuzzPoint({
  required DateTime pointAt,
  required DateTime? startedAt,
  required DateTime? endedAt,
  required Duration privacyWindow,
}) {
  if (startedAt != null &&
      pointAt.difference(startedAt).abs() <= privacyWindow) {
    return true;
  }
  if (endedAt != null && endedAt.difference(pointAt).abs() <= privacyWindow) {
    return true;
  }
  return false;
}

double _fuzzCoordinate(double value) {
  return double.parse(value.toStringAsFixed(3));
}

String _utcIso(DateTime value) {
  return value.toUtc().toIso8601String();
}

String _xml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
