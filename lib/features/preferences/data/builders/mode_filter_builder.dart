import 'package:nextstation/features/routing/domain/entities/routing_entities.dart';

/// Builds mode filters from restricted modes list.
/// Converts restriction list to include/exclude format for API.
class ModeFilterBuilder {
  static const List<String> supportedModes = <String>[
    'microbus',
    'tram',
    'minibus',
    'bus'
  ];

  /// Builds a ModeFilter from a list of restricted modes.
  static ModeFilter build(List<String> restrictedModes) {
    final normalized = restrictedModes
        .map((m) => m.trim().toLowerCase())
        .where((m) => m.isNotEmpty)
        .toSet();

    final allowedModes = supportedModes
        .where((m) => !normalized.contains(m))
        .toList(growable: false);

    return ModeFilter(
      include: allowedModes,
      exclude: normalized.toList(growable: false),
      includeMatch: 'any',
    );
  }
}
