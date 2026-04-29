import 'package:flutter/material.dart';

/// Displays a journey label chip with optional direction control.
/// Used for displaying journey labels (labels_ar, main_streets_ar).
class JourneyLabelChip extends StatelessWidget {
  final String label;
  final TextDirection textDirection;

  const JourneyLabelChip({
    super.key,
    required this.label,
    this.textDirection = TextDirection.ltr,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF455A64)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFECEFF1),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
