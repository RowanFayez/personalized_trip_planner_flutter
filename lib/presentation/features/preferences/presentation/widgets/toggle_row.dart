import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class ToggleRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double verticalPadding;

  const ToggleRow({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
    required this.onChanged,
    this.verticalPadding = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: verticalPadding.h,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30.r,
            height: 30.r,
            child: Center(child: leading),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.68,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primaryTeal,
              inactiveTrackColor: AppColors.surfaceDark,
              activeThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
