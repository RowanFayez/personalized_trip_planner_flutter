import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class PriorityTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final double height;

  const PriorityTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primaryTeal
        : AppColors.border.withValues(alpha: 0.55);
    final bgColor = selected
        ? AppColors.searchInputBackground.withValues(alpha: 0.72)
        : AppColors.searchInputBackground.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26.r),
        child: Container(
          width: width,
          height: height.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.primaryTeal
              : AppColors.border.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryTeal,
                ),
              ),
            )
          : null,
    );
  }
}
