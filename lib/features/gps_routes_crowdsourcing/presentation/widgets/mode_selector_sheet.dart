import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';

class ModeSelectorSheet extends StatelessWidget {
  final String title;
  final String? selectedMode;

  const ModeSelectorSheet({super.key, required this.title, this.selectedMode});

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? selectedMode,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ModeSelectorSheet(title: title, selectedMode: selectedMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 14.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: CrowdsourcingModes.selectable.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 2.7,
              ),
              itemBuilder: (context, index) {
                final mode = CrowdsourcingModes.selectable[index];
                final selected = mode == selectedMode;
                return _ModeTile(
                  mode: mode,
                  isSelected: selected,
                  onTap: () => Navigator.of(context).pop(mode),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String? mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = CrowdsourcingModes.color(mode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.22)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isSelected ? color : AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                CrowdsourcingModes.emoji(mode),
                style: TextStyle(fontSize: 20.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  CrowdsourcingModes.displayName(mode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
