import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/constants/app_colors.dart';

/// Set Preferences button for route options
class PreferencesButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PreferencesButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358.w,
      height: 47.h,
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(48.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(48.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(48.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune, color: AppColors.textPrimary, size: 20.r),
              SizedBox(width: 10.w),
              Text(
                'Set preferences',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
