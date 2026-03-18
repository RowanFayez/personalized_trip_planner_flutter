import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/domain/entities/routing_entities.dart';
import '../../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import 'routing_journey_utils.dart';

class RoutingRouteCard extends StatelessWidget {
  final Journey journey;
  final int total;
  final int index;
  final DateTime arrivalTime;
  final bool isBestRoute;
  final String routeLabel;

  const RoutingRouteCard({
    super.key,
    required this.journey,
    required this.total,
    required this.index,
    required this.arrivalTime,
    required this.isBestRoute,
    required this.routeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutingCubit>();
    final summary = journey.summary;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isBestRoute) const RoutingBestRouteBadge(),
              if (isBestRoute) SizedBox(width: 8.w),
              RoutingModeIconsRow(modes: summary.modes),
              const Spacer(),
              RoutingPill(label: routeLabel),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.totalTimeMinutes} min',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    '${RoutingJourneyUtils.formatTime(arrivalTime)} arrival • EGP${summary.cost.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
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
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'Route ${index + 1} of $total',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: total <= 1 ? null : cubit.previousJourney,
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: total <= 1 ? null : cubit.nextJourney,
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RoutingBestRouteBadge extends StatelessWidget {
  const RoutingBestRouteBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'BEST ROUTE',
        style: TextStyle(
          color: AppColors.primaryTeal,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class RoutingPill extends StatelessWidget {
  final String label;

  const RoutingPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 14, color: AppColors.textPrimary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RoutingModeIconsRow extends StatelessWidget {
  final List<String> modes;

  const RoutingModeIconsRow({super.key, required this.modes});

  @override
  Widget build(BuildContext context) {
    final items = modes.take(6).toList(growable: false);
    return Row(
      children: [
        for (final m in items) ...[
          RoutingModeIcon(mode: m),
          SizedBox(width: 6.w),
        ],
      ],
    );
  }
}

class RoutingModeIcon extends StatelessWidget {
  final String mode;

  const RoutingModeIcon({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final icon = _iconForMode(mode);
    return Container(
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 14.r, color: AppColors.textPrimary),
    );
  }

  IconData _iconForMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'walking':
      case 'walk':
        return Icons.directions_walk;
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
