import 'package:equatable/equatable.dart';

import '../../domain/entities/routing_entities.dart';

enum RoutingStatus { initial, loading, success, failure }

class RoutingState extends Equatable {
  final RoutingStatus status;
  final RoutingResult? result;
  final String? errorMessage;
  final int selectedJourneyIndex;

  const RoutingState({
    required this.status,
    this.result,
    this.errorMessage,
    required this.selectedJourneyIndex,
  });

  factory RoutingState.initial() {
    return const RoutingState(
      status: RoutingStatus.initial,
      selectedJourneyIndex: 0,
    );
  }

  RoutingState copyWith({
    RoutingStatus? status,
    RoutingResult? result,
    String? errorMessage,
    int? selectedJourneyIndex,
  }) {
    return RoutingState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
      selectedJourneyIndex: selectedJourneyIndex ?? this.selectedJourneyIndex,
    );
  }

  Journey? get selectedJourney {
    final journeys = result?.journeys;
    if (journeys == null || journeys.isEmpty) return null;

    final idx = selectedJourneyIndex.clamp(0, journeys.length - 1);
    return journeys[idx];
  }

  @override
  List<Object?> get props => [
    status,
    result,
    errorMessage,
    selectedJourneyIndex,
  ];
}
