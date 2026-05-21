import 'package:equatable/equatable.dart';

/// Immutable state for the fare feedback form.
class FareFeedbackState extends Equatable {
  /// Currently selected preset chip index, or null if none.
  final int? selectedChipIndex;

  /// Current validation error, or null if valid / untouched.
  final String? errorText;

  /// Whether the fare has been successfully submitted.
  final bool isSubmitted;

  const FareFeedbackState({
    this.selectedChipIndex,
    this.errorText,
    this.isSubmitted = false,
  });

  const FareFeedbackState.initial()
      : selectedChipIndex = null,
        errorText = null,
        isSubmitted = false;

  FareFeedbackState copyWith({
    int? Function()? selectedChipIndex,
    String? Function()? errorText,
    bool? isSubmitted,
  }) {
    return FareFeedbackState(
      selectedChipIndex: selectedChipIndex != null
          ? selectedChipIndex()
          : this.selectedChipIndex,
      errorText: errorText != null ? errorText() : this.errorText,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  @override
  List<Object?> get props => [selectedChipIndex, errorText, isSubmitted];
}
