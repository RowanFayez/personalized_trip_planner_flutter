import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class PreferencesPanel extends StatelessWidget {
  final Widget child;

  const PreferencesPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20.r), child: child),
    );
  }
}
