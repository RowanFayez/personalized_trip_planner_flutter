import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_colors.dart';
import 'routing_sheet_models.dart';

/// Timeline tile shown at the end of a journey when the last transit stop
/// is not at the user's destination (last-mile connection).
class RoutingFinalConnectionTile extends StatelessWidget {
  final RoutingFinalConnectionInfo info;
  final bool showTopConnector;
  final bool showBottomConnector;

  const RoutingFinalConnectionTile({
    super.key,
    required this.info,
    required this.showTopConnector,
    required this.showBottomConnector,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = 30.r;
    final dotCenterY = 18.h;
    final dotTop = dotCenterY - dotSize / 2;

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
                    left: (34.w - 2.w) / 2,
                    top: 0,
                    height: dotCenterY,
                    child: Container(width: 2.w, color: AppColors.surfaceLight),
                  ),
                if (showBottomConnector)
                  Positioned(
                    left: (34.w - 2.w) / 2,
                    top: dotCenterY,
                    bottom: 0,
                    child: Container(width: 2.w, color: AppColors.surfaceLight),
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.directions_walk_rounded,
                            size: 17.r,
                            color: AppColors.textSecondary,
                          ),
                          Positioned(
                            right: -5.w,
                            bottom: -4.h,
                            child: Text(
                              '🛺',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(fontSize: 10.sp),
                            ),
                          ),
                        ],
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
                    'امشي أو خد توكتوك إلى ${info.destinationName} '
                    '(المسافة المتبقية: ${info.distanceMeters} متر)',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
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
