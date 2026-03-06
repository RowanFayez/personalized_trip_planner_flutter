import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/saved_places_service.dart';

class QuickPlaceChips extends StatelessWidget {
  final ValueChanged<SavedPlaceType> onSelected;
  final VoidCallback onMore;

  const QuickPlaceChips({
    super.key,
    required this.onSelected,
    required this.onMore,
  });

  Widget _chip({
    required IconData icon,
    required String title,
    String subtitle = 'Set location',
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.searchInputBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 17.r),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 358.w,
      height: 46.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () => onSelected(SavedPlaceType.home),
          ),
          SizedBox(width: 10.w),
          _chip(
            icon: Icons.work_outline,
            title: 'Work',
            onTap: () => onSelected(SavedPlaceType.work),
          ),
          SizedBox(width: 10.w),
          _chip(
            icon: Icons.factory_outlined,
            title: 'College',
            onTap: () => onSelected(SavedPlaceType.college),
          ),
          SizedBox(width: 10.w),
          _chip(
            icon: Icons.more_horiz,
            title: 'More',
            subtitle: '',
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}
