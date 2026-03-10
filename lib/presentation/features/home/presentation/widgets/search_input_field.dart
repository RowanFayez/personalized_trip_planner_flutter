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
  final double? iconWidth;
  final double? iconHeight;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixTap;

  const SearchInputField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.svgAsset,
    this.iconWidth,
    this.iconHeight,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.suffixWidget,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    final inputFontSize = (15.sp <= 0) ? 15.0 : 15.sp;
    final hintFontSize = (15.sp <= 0) ? 15.0 : 15.sp;
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
            SvgPicture.asset(svgAsset, width: iconWidth, height: iconHeight),
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: inputFontSize,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: hintFontSize,
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
            if (suffixWidget != null) ...[
              GestureDetector(
                onTap: onSuffixTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                  child: suffixWidget!,
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ],
        ),
      ),
    );
  }
}
