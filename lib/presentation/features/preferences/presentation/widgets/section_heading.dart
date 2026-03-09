import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class SectionHeading extends StatelessWidget {
  final String text;
  final double fontSize;

  const SectionHeading({super.key, required this.text, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
