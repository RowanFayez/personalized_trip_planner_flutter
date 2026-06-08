import 'dart:io';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:xml/xml.dart';

import '../models/gps_point_model.dart';

class GpxTrackSegment {
  final int index;
  final String? mode;
  final List<Position> coordinates;

  const GpxTrackSegment({
    required this.index,
    required this.coordinates,
    this.mode,
  });
}

class GpxTrackReader {
  Future<List<GpxTrackSegment>> readSegments(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return const <GpxTrackSegment>[];
    final xml = await file.readAsString();
    final document = XmlDocument.parse(xml);
    final tracks = document.findAllElements('trk');
    final segments = <GpxTrackSegment>[];

    for (final track in tracks) {
      final index = _readInt(
        track.findAllElements('ns:segment_index').firstOrNull?.innerText ??
            track.findAllElements('segment_index').firstOrNull?.innerText,
      );
      final mode =
          track.findAllElements('ns:transit_mode').firstOrNull?.innerText ??
          track.findAllElements('transit_mode').firstOrNull?.innerText;
      final coordinates = track
          .findAllElements('trkpt')
          .map(_readPosition)
          .whereType<Position>()
          .toList(growable: false);
      if (coordinates.length < 2) continue;
      segments.add(
        GpxTrackSegment(
          index: index,
          mode: mode == null || mode == 'unknown' ? null : mode,
          coordinates: coordinates,
        ),
      );
    }

    return segments;
  }

  List<GpsPointModel> readGpsPointsFromXml(String xml) {
    final document = XmlDocument.parse(xml);
    final points = <GpsPointModel>[];
    var segmentIndex = 0;
    for (final track in document.findAllElements('trk')) {
      final parsedIndex = _readInt(
        track.findAllElements('ns:segment_index').firstOrNull?.innerText ??
            track.findAllElements('segment_index').firstOrNull?.innerText,
      );
      segmentIndex = parsedIndex;
      for (final trkpt in track.findAllElements('trkpt')) {
        final lat = double.tryParse(trkpt.getAttribute('lat') ?? '');
        final lon = double.tryParse(trkpt.getAttribute('lon') ?? '');
        if (lat == null || lon == null) continue;
        final time = trkpt.findElements('time').firstOrNull?.innerText;
        final parsedTime = time == null ? null : DateTime.tryParse(time);
        points.add(
          GpsPointModel(
            lat: lat,
            lon: lon,
            timestampMs:
                parsedTime?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            segmentIndex: segmentIndex,
          ),
        );
      }
    }
    return points;
  }

  Position? _readPosition(XmlElement point) {
    final lat = double.tryParse(point.getAttribute('lat') ?? '');
    final lon = double.tryParse(point.getAttribute('lon') ?? '');
    if (lat == null || lon == null) return null;
    return Position(lon, lat);
  }

  int _readInt(String? value) {
    return int.tryParse(value?.trim() ?? '') ?? 0;
  }
}

extension _XmlElementFirstOrNull on Iterable<XmlElement> {
  XmlElement? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
