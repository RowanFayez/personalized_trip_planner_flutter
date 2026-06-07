import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Banner row that navigates to the AI-agent chat page.
class RoutingChatRow extends StatelessWidget {
  const RoutingChatRow({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/agent'),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 16.r,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Chat about this route',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
