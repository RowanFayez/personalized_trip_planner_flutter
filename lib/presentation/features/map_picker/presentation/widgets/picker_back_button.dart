import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

/// Back arrow button positioned at the top-left of the map picker.
class PickerBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PickerBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 12.h, left: 16.w),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12.r),
            elevation: 4,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 44.r,
                height: 44.r,
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 22.r,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
