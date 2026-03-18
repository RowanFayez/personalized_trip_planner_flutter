import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/domain/entities/routing_entities.dart';

class RoutingStepCard extends StatelessWidget {
  final RouteLeg leg;

  const RoutingStepCard({super.key, required this.leg});

  @override
  Widget build(BuildContext context) {
    final title = _title();
    final subtitle = _subtitle();
    final trailing = _trailingFare();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoutingStepIcon(leg: leg),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 10.w), trailing],
        ],
      ),
    );
  }

  String _title() {
    if (leg.isWalk) {
      final to = leg.to?.name;
      return to == null || to.trim().isEmpty ? 'Walk' : 'Walk to $to';
    }

    if (leg.isTransfer) {
      return 'Transfer';
    }

    final mode = (leg.mode ?? 'trip').toUpperCase();
    final route = leg.routeShortName;
    if (route != null && route.trim().isNotEmpty) {
      return 'Take $route';
    }
    return 'Take $mode';
  }

  String? _subtitle() {
    if (leg.isWalk) {
      final from = leg.from?.name;
      final mins = leg.durationMinutes;
      final meters = leg.distanceMeters;

      final parts = <String>[];
      if (from != null && from.trim().isNotEmpty) parts.add(from);

      final details = <String>[];
      if (mins != null) details.add('$mins min');
      if (meters != null) details.add('${meters}m');
      if (details.isNotEmpty) parts.add(details.join(' • '));
      return parts.isEmpty ? null : parts.join(' - ');
    }

    if (leg.isTransfer) {
      final fromName = leg.fromTripName ?? leg.fromTripId;
      final toName = leg.toTripName ?? leg.toTripId;
      if (fromName != null && toName != null) {
        return 'Get off at $fromName • Transfer to $toName';
      }

      final walk = leg.walkingDistanceMeters;
      if (walk != null) return 'Walk $walk m';
      return null;
    }

    final from = leg.from?.name;
    final to = leg.to?.name;
    final mins = leg.durationMinutes;
    final parts = <String>[];

    if (from != null && to != null) {
      parts.add('$from → $to');
    }
    if (mins != null) {
      parts.add('$mins min');
    }
    return parts.isEmpty ? leg.headsign : parts.join(' • ');
  }

  Widget? _trailingFare() {
    final fare = leg.fare;
    if (fare == null || fare <= 0) return null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$fare EGP',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class RoutingStepIcon extends StatelessWidget {
  final RouteLeg leg;

  const RoutingStepIcon({super.key, required this.leg});

  @override
  Widget build(BuildContext context) {
    final icon = _iconData(leg);
    return Container(
      width: 34.r,
      height: 34.r,
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 18.r, color: AppColors.textPrimary),
    );
  }

  IconData _iconData(RouteLeg leg) {
    if (leg.isWalk) return Icons.directions_walk;
    if (leg.isTransfer) return Icons.compare_arrows;
    switch ((leg.mode ?? '').toLowerCase()) {
      case 'tram':
        return Icons.tram;
      case 'microbus':
      case 'minibus':
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.directions_transit;
    }
  }
}
