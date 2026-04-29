import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/routing/domain/entities/routing_entities.dart';
import 'journey_label_chip.dart';

/// Displays journey summary statistics (time, cost, transfers).
/// Shows Arabic labels and main streets as chips below stats.
class JourneySummaryStats extends StatelessWidget {
  final JourneySummary summary;
  final List<String> labelsAr;
  final List<String> mainStreetsAr;

  const JourneySummaryStats({
    super.key,
    required this.summary,
    required this.labelsAr,
    required this.mainStreetsAr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatChip(label: '${summary.totalTimeMinutes} min'),
            SizedBox(width: 8.w),
            _StatChip(label: '${summary.cost} EGP'),
            SizedBox(width: 8.w),
            _StatChip(label: '${summary.transfers} transfers'),
          ],
        ),
        if (labelsAr.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: labelsAr
                .where((s) => s.trim().isNotEmpty)
                .map(
                  (t) => JourneyLabelChip(
                    label: t,
                    textDirection: TextDirection.rtl,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (mainStreetsAr.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: mainStreetsAr
                .where((s) => s.trim().isNotEmpty)
                .map(
                  (t) => JourneyLabelChip(
                    label: t,
                    textDirection: TextDirection.rtl,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
