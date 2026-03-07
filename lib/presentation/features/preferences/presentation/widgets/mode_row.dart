import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import 'toggle_row.dart';

class ModeRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ModeRow({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleRow(
      leading: SvgPicture.asset(
        iconAsset,
        width: 22.r,
        height: 22.r,
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
      ),
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }
}
