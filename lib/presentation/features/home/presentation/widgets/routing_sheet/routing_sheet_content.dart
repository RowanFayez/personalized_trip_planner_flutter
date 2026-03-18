import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/animations/app_transitions.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/domain/entities/routing_entities.dart';
import '../../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../../features/routing/presentation/cubit/routing_state.dart';
import 'routing_chat_about_route_card.dart';
import 'routing_destination_card.dart';
import 'routing_journey_utils.dart';
import 'routing_route_card.dart';
import 'routing_step_card.dart';

class RoutingSheetContent extends StatelessWidget {
  final RoutingState state;
  final ScrollController scrollController;

  const RoutingSheetContent({
    super.key,
    required this.state,
    required this.scrollController,
  });

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

        final allJourneys = state.result?.journeys ?? const <Journey>[];
        final arrivalTime = DateTime.now().add(
          Duration(minutes: journey.summary.totalTimeMinutes),
        );
        final fastestIndex = RoutingJourneyUtils.findFastestIndex(allJourneys);
        final cheapestIndex = RoutingJourneyUtils.findCheapestIndex(
          allJourneys,
        );
        final lessWalkingIndex = RoutingJourneyUtils.findLessWalkingIndex(
          allJourneys,
        );

        final badgeLabel = index == fastestIndex
            ? 'Fastest'
            : index == cheapestIndex
            ? 'Cheapest'
            : index == lessWalkingIndex
            ? 'Less Walking'
            : 'Route';

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, anim) =>
                  AppTransitions.fadeSlide(child, anim),
              child: RoutingRouteCard(
                key: ValueKey('journey_${journey.id ?? index}'),
                journey: journey,
                total: total,
                index: index,
                arrivalTime: arrivalTime,
                isBestRoute: index == 0,
                routeLabel: badgeLabel,
              ),
            ),
            SizedBox(height: 8.h),
            const RoutingChatAboutRouteCard(),
            SizedBox(height: 10.h),
            ..._buildStepCards(journey.legs),
            SizedBox(height: 12.h),
            Center(
              child: Text(
                'Suggest an edit',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 54.h,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'View All Routes',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );

      case RoutingStatus.initial:
        return const SizedBox();
    }
  }

  List<Widget> _buildStepCards(List<RouteLeg> legs) {
    final tiles = <Widget>[];

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      tiles.add(RoutingStepCard(leg: leg));
      if (i != legs.length - 1) {
        tiles.add(SizedBox(height: 10.h));
      }
    }

    final destinationName = legs.isEmpty
        ? null
        : (legs.last.to?.name ?? legs.last.from?.name);

    tiles.add(SizedBox(height: 10.h));
    tiles.add(RoutingDestinationCard(destinationName: destinationName));

    return tiles;
  }
}
