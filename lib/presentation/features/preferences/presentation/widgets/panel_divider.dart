import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider.withValues(alpha: 0.35),
    );
  }
}
