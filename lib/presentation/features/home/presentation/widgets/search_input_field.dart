import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/constants/app_colors.dart';

/// Reusable search input field for From/To locations
class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final String svgAsset;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixWidget;

  const SearchInputField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.svgAsset,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            SizedBox(width: 16.w),
            SvgPicture.asset(svgAsset, width: 12.w, height: 12.h),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onTap: onTap,
                onChanged: onChanged,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                cursorColor: AppColors.textPrimary,
                selectionControls: materialTextSelectionControls,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 15.sp,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (suffixWidget != null) ...[suffixWidget!, SizedBox(width: 8.w)],
          ],
        ),
      ),
    );
  }
}
