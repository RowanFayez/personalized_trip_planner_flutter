import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/domain/entities/routing_entities.dart';
import '../journey_summary_stats.dart';

/// Card displaying journey stats, text summary, and fare-feedback button.
class RoutingJourneySummary extends StatelessWidget {
  final Journey journey;

  const RoutingJourneySummary({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final summary = journey.summary;
    final labelsAr = journey.labelsAr;
    final mainStreetsAr = summary.mainStreetsAr;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JourneySummaryStats(
            summary: summary,
            labelsAr: labelsAr,
            mainStreetsAr: mainStreetsAr,
          ),
          if ((journey.textSummary ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              journey.textSummary!,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
          // ── Fare Feedback button for total route ──
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => context.push('/fare-feedback?isTotalRoute=true'),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18.r,
                      color: AppColors.primaryTeal,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Fare Feedback',
                      style: TextStyle(
                        color: AppColors.primaryTeal,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
