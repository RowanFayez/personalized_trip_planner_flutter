import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_colors.dart';

class RoutingGrabHandle extends StatelessWidget {
  const RoutingGrabHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
