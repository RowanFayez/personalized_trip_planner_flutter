import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class RoutePreferencesHeader extends StatelessWidget {
  final VoidCallback onClose;

  const RoutePreferencesHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.textPrimary, size: 20.r),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: 36.w, height: 36.h),
              onPressed: onClose,
            ),
          ),
          Text(
            'Route Preferences',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
