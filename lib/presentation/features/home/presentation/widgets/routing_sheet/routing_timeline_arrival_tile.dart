import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Timeline arrival tile — the last node in the journey timeline.
class RoutingTimelineArrivalTile extends StatelessWidget {
  final String? destinationName;
  final bool showTopConnector;

  const RoutingTimelineArrivalTile({
    super.key,
    required this.destinationName,
    required this.showTopConnector,
  });

  @override
  Widget build(BuildContext context) {
    const dotSize = 30.0;
    final dotCenterY = 18.h;
    final dotTop = dotCenterY - dotSize / 2;
    final label = (destinationName ?? 'Destination').trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34.w,
            child: Stack(
              children: [
                if (showTopConnector)
                  Positioned(
                    left: (34.w - 2) / 2,
                    top: 0,
                    height: dotCenterY,
                    child: Container(width: 2, color: AppColors.surfaceLight),
                  ),
                Positioned(
                  top: dotTop,
                  left: (34.w - dotSize) / 2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: AppColors.searchInputBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on,
                        size: 16.r,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.searchInputBackground,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'You have arrived at your destination.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
