/// Polyline5 decoder for Google Maps encoded polylines.
/// Converts encoded polyline strings to GeoPoint lists for map rendering.
class PolylineDecoder {
  /// Decodes a polyline5-encoded string into a list of lat/lon coordinates.
  /// Returns an empty list if the input is empty or decoding fails.
  static List<(double, double)> decode(String? encoded) {
    final value = (encoded ?? '').trim();
    if (value.isEmpty) return const <(double, double)>[];

    final points = <(double, double)>[];
    var index = 0;
    var lat = 0;
    var lon = 0;

    try {
      while (index < value.length) {
        final latResult = _decodeComponent(value, startIndex: index);
        index = latResult.nextIndex;
        lat += latResult.delta;

        if (index >= value.length) break;

        final lonResult = _decodeComponent(value, startIndex: index);
        index = lonResult.nextIndex;
        lon += lonResult.delta;

        points.add((lat / 1e5, lon / 1e5));
      }
    } catch (_) {
      // Return best-effort points collected so far
    }

    return List<(double, double)>.unmodifiable(points);
  }

  /// Decodes a single component of a polyline5 string.
  static ({int delta, int nextIndex}) _decodeComponent(
    String encoded, {
    required int startIndex,
  }) {
    var result = 0;
    var shift = 0;
    var index = startIndex;

    while (index < encoded.length) {
      final b = encoded.codeUnitAt(index) - 63;
      index++;
      result |= (b & 0x1f) << shift;
      shift += 5;
      if (b < 0x20) break;
    }

    final delta = (result & 1) == 1 ? ~(result >> 1) : (result >> 1);
    return (delta: delta, nextIndex: index);
  }
}
