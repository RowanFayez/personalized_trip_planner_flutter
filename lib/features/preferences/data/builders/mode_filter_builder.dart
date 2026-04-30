import 'package:nextstation/features/routing/domain/entities/routing_entities.dart';

/// Builds mode filters from restricted modes list.
/// Converts restriction list to include/exclude format for API.
class ModeFilterBuilder {
  static const List<String> supportedModes = <String>[
    'microbus',
    'tram',
    'minibus',
    'bus',
  ];

  /// Builds a ModeFilter from a list of restricted modes.
  static ModeFilter build(List<String> restrictedModes) {
    final normalized = restrictedModes
        .map((m) => m.trim().toLowerCase())
        .where((m) => m.isNotEmpty)
        .toSet();

    // IMPORTANT:
    // We only use `exclude` to block disabled modes.
    // Sending a non-empty `include` can inadvertently block walking/transfer
    // legs and cause "No routes" even when the excluded mode isn't used.
    final excludedModes = supportedModes
        .where(normalized.contains)
        .toList(growable: false);

    return ModeFilter(
      include: const <String>[],
      exclude: excludedModes,
      includeMatch: 'any',
    );
  }
}
