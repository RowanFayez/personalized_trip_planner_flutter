import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

/// Bottom card that shows the resolved place name & confirm button.
class PickerLocationCard extends StatelessWidget {
  final String fieldLabel;
  final String? placeName;
  final String? placeSubtitle;
  final bool isMoving;
  final bool isGeocoding;
  final VoidCallback onConfirm;

  const PickerLocationCard({
    super.key,
    required this.fieldLabel,
    required this.placeName,
    required this.placeSubtitle,
    required this.isMoving,
    required this.isGeocoding,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context).bottom;
    final label = switch (fieldLabel) {
      'from' => 'Pickup point',
      'to' => 'Drop-off point',
      'home' => 'Home',
      'work' => 'Work',
      'college' => 'College',
      _ => fieldLabel,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h + safePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small label
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 6.h),

          // Place name or loading state
          if (isMoving)
            _buildPlaceholder('Moving…')
          else if (isGeocoding)
            _buildLoading()
          else if (placeName != null)
            _buildPlaceName()
          else
            _buildPlaceholder('Move the map to pick a location'),

          SizedBox(height: 16.h),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: (placeName != null && !isMoving && !isGeocoding)
                  ? onConfirm
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                disabledBackgroundColor: AppColors.surfaceDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          placeName!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        if (placeSubtitle != null && placeSubtitle!.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            placeSubtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        SizedBox(
          width: 18.r,
          height: 18.r,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryTeal,
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          'Finding location…',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    return Text(
      text,
      style: TextStyle(color: AppColors.textHint, fontSize: 16.sp),
    );
  }
}
