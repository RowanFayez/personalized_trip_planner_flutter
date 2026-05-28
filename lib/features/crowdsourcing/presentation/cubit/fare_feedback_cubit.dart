import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/fare_feedback_validator.dart';
import 'fare_feedback_state.dart';

/// Cubit that manages fare feedback form interactions.
///
/// All business logic lives here — the page and widgets are
/// purely presentational.
class FareFeedbackCubit extends Cubit<FareFeedbackState> {
  FareFeedbackCubit() : super(const FareFeedbackState.initial());

  /// Called when the user types in the fare input field.
  ///
  /// Clears chip selection and live-clears validation errors.
  void onInputChanged(String value) {
    final updates = <String, dynamic>{};

    // Clear chip selection when typing manually.
    if (state.selectedChipIndex != null) {
      updates['chip'] = true;
    }

    // Live-clear the error once the input becomes valid.
    if (state.errorText != null) {
      final err = FareFeedbackValidator.validate(value);
      if (err == null) {
        updates['error'] = true;
      }
    }

    if (updates.isNotEmpty) {
      emit(state.copyWith(
        selectedChipIndex:
            updates.containsKey('chip') ? () => null : null,
        errorText: updates.containsKey('error') ? () => null : null,
      ));
    }
  }

  /// Called when the user taps a preset chip.
  ///
  /// Returns the preset value as a string to set in the text controller.
  String onChipSelected(int index) {
    emit(state.copyWith(
      selectedChipIndex: () => index,
      errorText: () => null,
    ));
    return FareFeedbackValidator.presets[index].toString();
  }

  /// Validates and confirms the fare.
  ///
  /// Returns the parsed amount on success, or null if validation fails.
  double? onConfirm(String inputText) {
    final error = FareFeedbackValidator.validate(inputText);
    if (error != null) {
      emit(state.copyWith(errorText: () => error));
      return null;
    }

    final amount = FareFeedbackValidator.parse(inputText);
    emit(state.copyWith(
      errorText: () => null,
      isSubmitted: true,
    ));

    // TODO: Send fare data to backend via crowdsourcing repository.
    debugPrint('Fare confirmed: $amount EGP');

    return amount;
  }
}
