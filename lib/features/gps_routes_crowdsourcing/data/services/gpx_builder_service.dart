import 'dart:io';
import 'dart:math' as math;

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

  final fuzzedPointKeys = _fuzzedPointKeys(points);

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
      '      <ns:route_name>${_xml(tripMeta.routeName ?? '')}</ns:route_name>',
    )
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
      final shouldFuzz = fuzzedPointKeys.contains(_pointKey(point));
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

Set<String> _fuzzedPointKeys(List<GpsPointModel> points) {
  if (points.isEmpty) return <String>{};
  final sorted = List<GpsPointModel>.of(points, growable: false)
    ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  final fuzzed = <String>{};
  _addDistanceWindow(sorted, fuzzed);
  _addDistanceWindow(sorted.reversed.toList(growable: false), fuzzed);
  return fuzzed;
}

void _addDistanceWindow(List<GpsPointModel> points, Set<String> fuzzed) {
  if (points.isEmpty) return;
  fuzzed.add(_pointKey(points.first));
  var distance = 0.0;
  for (var index = 1; index < points.length; index += 1) {
    final previous = points[index - 1];
    final current = points[index];
    distance += _distanceBetween(
      previous.lat,
      previous.lon,
      current.lat,
      current.lon,
    );
    fuzzed.add(_pointKey(current));
    if (distance >= CrowdsourcingLimits.privacyFuzzingDistanceM) return;
  }
}

String _pointKey(GpsPointModel point) {
  return '${point.timestampMs}:${point.segmentIndex}:${point.lat}:${point.lon}';
}

double _fuzzCoordinate(double value) {
  return double.parse(value.toStringAsFixed(3));
}

double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusM = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusM * c;
}

double _degToRad(double degrees) => degrees * math.pi / 180;

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
