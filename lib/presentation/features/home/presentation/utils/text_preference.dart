/// Utility for selecting preferred text language (Arabic over English).
class TextPreference {
  /// Returns Arabic text if available, falls back to English, then returns null.
  static String? preferred(String? ar, String? en) {
    final arabic = (ar ?? '').trim();
    if (arabic.isNotEmpty) return arabic;
    final english = (en ?? '').trim();
    if (english.isNotEmpty) return english;
    return null;
  }

  /// Capitalizes first letter only if it's ASCII (not Arabic text).
  static String capitalize(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    // Check if first character is ASCII letter
    final first = trimmed.codeUnitAt(0);
    final isAsciiLetter = (first >= 65 && first <= 90) || (first >= 97 && first <= 122);
    if (!isAsciiLetter) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
