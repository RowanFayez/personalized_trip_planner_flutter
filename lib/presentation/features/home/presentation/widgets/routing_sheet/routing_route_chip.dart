import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_colors.dart';

/// Colored chip showing a route label (e.g. route number or mode name).
class RoutingRouteChip extends StatelessWidget {
  final String label;
  final String mode;

  const RoutingRouteChip({
    super.key,
    required this.label,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(mode);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _modeColor(String mode) {
    final m = mode.trim().toLowerCase();
    if (m.contains('walk') || m == 'walking') return AppColors.walkColor;
    if (m.contains('micro')) return AppColors.tramColor;
    if (m.contains('mini')) return AppColors.minibusColor;
    if (m.contains('bus')) return AppColors.busColor;
    if (m.contains('tram') ||
        m.contains('metro') ||
        m.contains('subway') ||
        m.contains('rail') ||
        m.contains('line')) {
      return AppColors.routeLine;
    }
    if (m.contains('tonaya') || m.contains('taxi')) {
      return AppColors.tonayaColor;
    }
    return AppColors.routeLine;
  }
}
