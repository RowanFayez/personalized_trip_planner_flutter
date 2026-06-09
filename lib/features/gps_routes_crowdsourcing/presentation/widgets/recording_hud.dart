import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';

class RecordingHud extends StatelessWidget {
  final String modeDisplay;
  final String? mode;
  final int elapsedSeconds;
  final double distanceM;
  final bool isGpsLost;
  final bool isFollowing;

  const RecordingHud({
    super.key,
    required this.modeDisplay,
    required this.mode,
    required this.elapsedSeconds,
    required this.distanceM,
    required this.isGpsLost,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(CrowdsourcingUi.screenPadding.w),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: CrowdsourcingModes.color(mode)),
                ),
                child: Text(
                  '${CrowdsourcingModes.emoji(mode)} $modeDisplay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            _StatPill(text: _formatElapsed(elapsedSeconds)),
            SizedBox(width: 8.w),
            _StatPill(text: '${(distanceM / 1000).toStringAsFixed(1)} km'),
            if (isGpsLost) ...[
              SizedBox(width: 8.w),
              const Icon(Icons.gps_off_rounded, color: AppColors.warning),
            ],
            if (!isFollowing) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.gps_not_fixed_rounded,
                color: AppColors.textTertiary,
                size: 16.r,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatElapsed(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }
}

class _StatPill extends StatelessWidget {
  final String text;

  const _StatPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
