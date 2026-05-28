import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/fare_feedback_validator.dart';
import 'fare_chip.dart';

/// A horizontally wrapping row of preset fare chips.
///
/// Delegates selection to the parent via [onChipSelected].
class FareChipsRow extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int> onChipSelected;

  const FareChipsRow({
    super.key,
    required this.selectedIndex,
    required this.onChipSelected,
  });

  @override
  Widget build(BuildContext context) {
    final presets = FareFeedbackValidator.presets;

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: List.generate(presets.length, (i) {
        return FareChip(
          label: 'EGP ${presets[i]}',
          isSelected: selectedIndex == i,
          onTap: () => onChipSelected(i),
        );
      }),
    );
  }
}
