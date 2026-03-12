import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

class StopIconService {
  Uint8List? _cachedIconBytes;

  Future<Uint8List> loadOptimizedStopIconBytes() async {
    if (_cachedIconBytes != null) return _cachedIconBytes!;

    final data = await rootBundle.load('assets/icons/stops.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 155,
      targetHeight: 155,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    _cachedIconBytes = byteData?.buffer.asUint8List() ?? data.buffer.asUint8List();
    return _cachedIconBytes!;
  }
}