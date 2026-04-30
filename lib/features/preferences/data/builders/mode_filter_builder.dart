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

    // Exclude: modes that are OFF.
    final excludedModes = supportedModes
        .where(normalized.contains)
        .toList(growable: false);

    // Include: modes that are ON.
    // If all are ON, send empty include => backend treats as "all allowed".
    final includedModes = supportedModes
        .where((m) => !normalized.contains(m))
        .toList(growable: false);

    final include = includedModes.length == supportedModes.length
        ? const <String>[]
        : includedModes;

    return ModeFilter(
      include: include,
      exclude: excludedModes,
      includeMatch: 'any',
    );
  }
}
