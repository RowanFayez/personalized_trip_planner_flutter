import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../data/models/trip_metadata_model.dart';

class ContributionListItem extends StatelessWidget {
  final TripMetadataModel trip;
  final VoidCallback? onAction;
  final VoidCallback? onDelete;

  const ContributionListItem({
    super.key,
    required this.trip,
    this.onAction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFor(trip.status);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            trip.routeName?.trim().isNotEmpty == true
                ? trip.routeName!
                : _formatDate(trip.startedAt),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (trip.routeName?.trim().isNotEmpty == true) ...[
            SizedBox(height: 4.h),
            Text(
              _formatDate(trip.startedAt),
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Text(
            trip.segments
                .map((s) => CrowdsourcingModes.emoji(s.mode))
                .join(' → '),
            style: TextStyle(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            '${((trip.totalDistanceM ?? 0) / 1000).toStringAsFixed(1)} km · '
            '${trip.segments.length} segments · '
            '${_totalFare().toStringAsFixed(0)} ${CrowdsourcingStrings.egp}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _StatusBadge(label: badge.label, color: badge.color),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                tooltip: CrowdsourcingStrings.deleteTrip,
              ),
              if (_actionLabel() != null)
                TextButton(onPressed: onAction, child: Text(_actionLabel()!))
              else if (trip.status == TripStatuses.pendingUpload)
                SizedBox.square(
                  dimension: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _badgeFor(String status) {
    return switch (status) {
      TripStatuses.uploaded => (
        label: CrowdsourcingStrings.uploadedBadge,
        color: AppColors.success,
      ),
      TripStatuses.uploadFailed => (
        label: CrowdsourcingStrings.uploadFailedBadge,
        color: AppColors.error,
      ),
      TripStatuses.pendingUpload => (
        label: CrowdsourcingStrings.pendingUploadBadge,
        color: AppColors.warning,
      ),
      _ => (
        label: CrowdsourcingStrings.pendingReviewBadge,
        color: AppColors.primaryTeal,
      ),
    };
  }

  String? _actionLabel() {
    return switch (trip.status) {
      TripStatuses.pendingReview => CrowdsourcingStrings.submit,
      TripStatuses.uploadFailed => CrowdsourcingStrings.retry,
      TripStatuses.uploaded => CrowdsourcingStrings.edit,
      _ => null,
    };
  }

  double _totalFare() {
    return trip.segments.fold<double>(
      0,
      (sum, segment) => sum + (segment.fareEgp ?? 0),
    );
  }

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const arabicMonths = <String>[
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final hour = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${parsed.day} ${arabicMonths[parsed.month]} '
        '${parsed.year} · $displayHour:$minute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
