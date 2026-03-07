import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.divider.withValues(alpha: 0.55),
      height: 1,
    );
  }
}
