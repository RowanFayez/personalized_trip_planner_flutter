import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class SectionHeading extends StatelessWidget {
  final String text;

  const SectionHeading({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
