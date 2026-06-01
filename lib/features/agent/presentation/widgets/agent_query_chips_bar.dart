import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class AgentQueryChipsBar extends StatelessWidget {
  final ValueChanged<String> onQuerySelected;
  final List<String> queries;

  const AgentQueryChipsBar({
    super.key,
    required this.onQuerySelected,
    required this.queries,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: queries.length,
        itemBuilder: (context, index) {
          final query = queries[index];
          return Padding(
            padding: EdgeInsetsDirectional.only(
              end: index == queries.length - 1 ? 0 : 10.w,
            ),
            child: _QueryChip(
              label: query,
              onTap: () => onQuerySelected(query),
            ),
          );
        },
      ),
    );
  }
}

class _QueryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QueryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.searchInputBackground.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18.r,
                height: 18.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 11.r,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: _containsArabic(label)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }
}
