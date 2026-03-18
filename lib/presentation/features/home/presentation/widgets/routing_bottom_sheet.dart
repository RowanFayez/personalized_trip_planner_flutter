import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/animations/app_transitions.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/routing/domain/entities/routing_entities.dart';
import '../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../features/routing/presentation/cubit/routing_state.dart';

class RoutingBottomSheet extends StatelessWidget {
  const RoutingBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingCubit, RoutingState>(
      builder: (context, state) {
        if (state.status == RoutingStatus.initial) return const SizedBox();

        return DraggableScrollableSheet(
          minChildSize: 0.16,
          initialChildSize: 0.26,
          maxChildSize: 0.78,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.searchInputBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  _GrabHandle(),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: _SheetContent(
                      state: state,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GrabHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  final RoutingState state;
  final ScrollController scrollController;

  const _SheetContent({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case RoutingStatus.loading:
        return Center(
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: const CircularProgressIndicator(
              color: AppColors.primaryTeal,
            ),
          ),
        );

      case RoutingStatus.failure:
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          children: [
            Text(
              state.errorMessage ?? 'Something went wrong.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 46.h,
              child: ElevatedButton(
                onPressed: () {
                  // Keep the sheet open; user can reselect points.
                  context.read<RoutingCubit>().clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        );

      case RoutingStatus.success:
        final journey = state.selectedJourney;
        if (journey == null) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            children: [
              Text(
                'No routes found.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        final total = state.result?.journeys.length ?? 0;
        final index = state.selectedJourneyIndex;

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          children: [
            _HeaderRow(total: total, index: index),
            SizedBox(height: 10.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, anim) =>
                  AppTransitions.fadeSlide(child, anim),
              child: _JourneySummary(
                key: ValueKey('journey_${journey.id ?? index}'),
                journey: journey,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Steps',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            ..._buildLegTiles(journey.legs),
          ],
        );

      case RoutingStatus.initial:
        return const SizedBox();
    }
  }

  List<Widget> _buildLegTiles(List<RouteLeg> legs) {
    final tiles = <Widget>[];

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      tiles.add(_LegTile(leg: leg, index: i + 1));
      if (i != legs.length - 1) {
        tiles.add(SizedBox(height: 8.h));
        tiles.add(Divider(color: AppColors.divider, height: 1.h));
        tiles.add(SizedBox(height: 8.h));
      }
    }

    return tiles;
  }
}

class _HeaderRow extends StatelessWidget {
  final int total;
  final int index;

  const _HeaderRow({required this.total, required this.index});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutingCubit>();

    return Row(
      children: [
        Text(
          'Route ${index + 1} of $total',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: total <= 1 ? null : cubit.previousJourney,
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: total <= 1 ? null : cubit.nextJourney,
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _JourneySummary extends StatelessWidget {
  final Journey journey;

  const _JourneySummary({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final summary = journey.summary;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
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
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
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

class _LegTile extends StatelessWidget {
  final RouteLeg leg;
  final int index;

  const _LegTile({required this.leg, required this.index});

  @override
  Widget build(BuildContext context) {
    final title = _legTitle(leg);
    final subtitle = _legSubtitle(leg);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegIndex(index: index, leg: leg),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4.h),
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
      ],
    );
  }

  String _legTitle(RouteLeg leg) {
    if (leg.isWalk) {
      final mins = leg.durationMinutes;
      return mins == null ? 'Walk' : 'Walk ($mins min)';
    }

    if (leg.isTransfer) {
      return 'Transfer';
    }

    final mode = (leg.mode ?? 'trip').toUpperCase();
    final route = leg.routeShortName;
    if (route != null && route.trim().isNotEmpty) {
      return '$mode • $route';
    }

    return mode;
  }

  String? _legSubtitle(RouteLeg leg) {
    if (leg.isWalk) {
      final meters = leg.distanceMeters;
      if (meters == null) return null;
      return '$meters m';
    }

    if (leg.isTransfer) {
      final fromName = leg.fromTripName ?? leg.fromTripId;
      final toName = leg.toTripName ?? leg.toTripId;

      if (fromName != null && toName != null) {
        return 'From $fromName to $toName';
      }

      final walk = leg.walkingDistanceMeters;
      if (walk != null) return 'Walk $walk m';

      return null;
    }

    final from = leg.from?.name;
    final to = leg.to?.name;

    if (from != null && to != null) {
      final headsign = leg.headsign;
      return headsign == null || headsign.trim().isEmpty
          ? '$from → $to'
          : '$from → $to\n$headsign';
    }

    return leg.headsign;
  }
}

class _LegIndex extends StatelessWidget {
  final int index;
  final RouteLeg leg;

  const _LegIndex({required this.index, required this.leg});

  @override
  Widget build(BuildContext context) {
    final icon = _iconData(leg);

    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 16.r, color: AppColors.textPrimary)
            : Text(
                index.toString(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  IconData? _iconData(RouteLeg leg) {
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
