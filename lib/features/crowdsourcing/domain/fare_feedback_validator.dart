/// Pure domain-level validation for fare feedback input.
///
/// Stateless and testable — no Flutter/UI dependencies.
class FareFeedbackValidator {
  FareFeedbackValidator._();

  /// Preset fare amounts shown as quick-select chips.
  static const List<int> presets = [5, 7, 10, 15];

  /// Minimum accepted fare (inclusive).
  static const double minFare = 1;

  /// Maximum accepted fare (inclusive).
  static const double maxFare = 100;

  /// Validates a raw fare string.
  ///
  /// Returns `null` when valid, or a human-readable error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a fare amount';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < minFare || parsed > maxFare) {
      return 'Fare must be between ${minFare.toInt()} and ${maxFare.toInt()} EGP';
    }
    return null;
  }

  /// Parses a validated fare string into a [double].
  ///
  /// Call only after [validate] returns null.
  static double parse(String value) => double.parse(value.trim());

  /// Formats a confirmed fare amount for display.
  static String formatAmount(double amount) {
    return amount.truncateToDouble() == amount
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }
}
