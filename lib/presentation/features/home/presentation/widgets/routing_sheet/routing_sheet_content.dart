import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/animations/app_transitions.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/domain/entities/routing_entities.dart';
import '../../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../../features/routing/presentation/cubit/routing_state.dart';
import '../../utils/text_preference.dart';
import 'routing_chat_row.dart';
import 'routing_final_connection_tile.dart';
import 'routing_first_connection_tile.dart';
import 'routing_header_row.dart';
import 'routing_journey_summary.dart';
import 'routing_sheet_models.dart';
import 'routing_timeline_arrival_tile.dart';
import 'routing_timeline_step_tile.dart';

/// Scrollable body of the routing bottom sheet.
///
/// Switches between loading, failure and success states; builds the full
/// timeline leg list when routes are available.
class RoutingSheetContent extends StatelessWidget {
  static const double _samePointToleranceMeters = 0.5;

  final RoutingState state;
  final ScrollController scrollController;
  final String? requestedOriginName;
  final double? requestedOriginLatitude;
  final double? requestedOriginLongitude;
  final String? requestedDestinationName;
  final double? requestedDestinationLatitude;
  final double? requestedDestinationLongitude;

  const RoutingSheetContent({
    super.key,
    required this.state,
    required this.scrollController,
    this.requestedOriginName,
    this.requestedOriginLatitude,
    this.requestedOriginLongitude,
    this.requestedDestinationName,
    this.requestedDestinationLatitude,
    this.requestedDestinationLongitude,
  });

  double _safeBottomSpacing(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 16.h;
  }

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case RoutingStatus.loading:
        return Center(
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryTeal),
                SizedBox(height: 12.h),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'جاري الاتصال بالخادم، يرجى الانتظار...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case RoutingStatus.failure:
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                state.errorMessage ??
                    'عفواً، لا توجد مسارات متاحة. حاول تغيير نقطة البداية أو النهاية، أو تعديل تفضيلات البحث.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 46.h,
              child: ElevatedButton(
                onPressed: () => context.read<RoutingCubit>().clear(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: const Text('إغلاق'),
              ),
            ),
            SizedBox(height: _safeBottomSpacing(context)),
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
                'لا توجد مسارات متاحة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: _safeBottomSpacing(context)),
            ],
          );
        }

        final total = state.result?.journeys.length ?? 0;
        final index = state.selectedJourneyIndex;
        final destinationName = _destinationName(journey.legs);
        final firstConnection = _firstConnectionInfo(journey.legs);
        final finalConnection = _finalConnectionInfo(journey.legs);
        final arrivalName =
            finalConnection?.destinationName ?? destinationName;

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          children: [
            const RoutingChatRow(),
            SizedBox(height: 10.h),
            RoutingHeaderRow(total: total, index: index),
            SizedBox(height: 10.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, anim) =>
                  AppTransitions.fadeSlide(child, anim),
              child: RoutingJourneySummary(
                key: ValueKey('journey_${journey.id ?? index}'),
                journey: journey,
              ),
            ),
            SizedBox(height: 12.h),
            ..._buildLegTiles(
              journey.legs,
              destinationName: destinationName,
              firstConnection: firstConnection,
              finalConnection: finalConnection,
              arrivalDestinationName: arrivalName,
            ),
            SizedBox(height: _safeBottomSpacing(context)),
          ],
        );

      case RoutingStatus.initial:
        return const SizedBox();
    }
  }

  // ── Destination name resolution ───────────────────────────────────────────

  String? _destinationName(List<RouteLeg> legs) {
    for (var i = legs.length - 1; i >= 0; i--) {
      final name = TextPreference.preferred(
        legs[i].to?.nameAr,
        legs[i].to?.name,
      );
      if (name != null) return name;
    }
    return null;
  }

  // ── Timeline tile list builder ────────────────────────────────────────────

  List<Widget> _buildLegTiles(
    List<RouteLeg> legs, {
    required String? destinationName,
    required RoutingFirstConnectionInfo? firstConnection,
    required RoutingFinalConnectionInfo? finalConnection,
    required String? arrivalDestinationName,
  }) {
    final tiles = <Widget>[];

    // ── First-mile connection tile (origin → first stop) ──
    if (firstConnection != null) {
      tiles.add(
        RoutingFirstConnectionTile(
          info: firstConnection,
          showTopConnector: false,
          showBottomConnector: true,
        ),
      );
      tiles.add(SizedBox(height: 10.h));
    }

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      final nextLeg = i + 1 < legs.length ? legs[i + 1] : null;
      final isFirst = i == 0;
      final isLastLeg = i == legs.length - 1;

      tiles.add(
        RoutingTimelineStepTile(
          leg: leg,
          nextLeg: nextLeg,
          destinationName: destinationName,
          showTopConnector: !isFirst || firstConnection != null,
          showBottomConnector: true,
        ),
      );

      if (i != legs.length - 1) tiles.add(SizedBox(height: 10.h));

      if (isLastLeg) {
        tiles.add(SizedBox(height: 10.h));
        if (finalConnection != null) {
          tiles.add(
            RoutingFinalConnectionTile(
              info: finalConnection,
              showTopConnector: true,
              showBottomConnector: true,
            ),
          );
          tiles.add(SizedBox(height: 10.h));
        }
        tiles.add(
          RoutingTimelineArrivalTile(
            destinationName: arrivalDestinationName,
            showTopConnector: true,
          ),
        );
      }
    }

    return tiles;
  }

  // ── First-mile connection (origin → first route point) ───────────────────

  RoutingFirstConnectionInfo? _firstConnectionInfo(List<RouteLeg> legs) {
    final originName = (requestedOriginName ?? '').trim();
    if (legs.isEmpty) return null;

    final requestedLat = requestedOriginLatitude;
    final requestedLon = requestedOriginLongitude;
    final firstRoutePoint = _firstRoutePoint(legs);

    if (requestedLat == null ||
        requestedLon == null ||
        firstRoutePoint == null) {
      return null;
    }

    final distance = _distanceMeters(
      requestedLat,
      requestedLon,
      firstRoutePoint.lat,
      firstRoutePoint.lon,
    );
    if (distance <= _samePointToleranceMeters) return null;

    return RoutingFirstConnectionInfo(
      originName: originName.isNotEmpty ? originName : 'نقطة البداية',
      distanceMeters: math.max(1, distance.round()),
    );
  }

  // ── Last-mile connection (last route point → destination) ─────────────────

  RoutingFinalConnectionInfo? _finalConnectionInfo(List<RouteLeg> legs) {
    final destinationName = (requestedDestinationName ?? '').trim();
    if (legs.isEmpty) return null;

    final requestedLat = requestedDestinationLatitude;
    final requestedLon = requestedDestinationLongitude;
    final lastRoutePoint = _lastRoutePoint(legs);

    if (requestedLat == null ||
        requestedLon == null ||
        lastRoutePoint == null) {
      return null;
    }

    final distance = _distanceMeters(
      lastRoutePoint.lat,
      lastRoutePoint.lon,
      requestedLat,
      requestedLon,
    );
    if (distance <= _samePointToleranceMeters) return null;

    return RoutingFinalConnectionInfo(
      destinationName:
          destinationName.isNotEmpty ? destinationName : 'وجهتك',
      distanceMeters: math.max(1, distance.round()),
    );
  }

  ({double lat, double lon})? _firstRoutePoint(List<RouteLeg> legs) {
    for (var i = 0; i < legs.length; i++) {
      final path = legs[i].path;
      if (path.isNotEmpty) {
        final first = path.first;
        return (lat: first.lat, lon: first.lon);
      }

      final stop = legs[i].from;
      if (stop != null) {
        return (lat: stop.coord.lat, lon: stop.coord.lon);
      }
    }
    return null;
  }

  ({double lat, double lon})? _lastRoutePoint(List<RouteLeg> legs) {
    for (var i = legs.length - 1; i >= 0; i--) {
      final path = legs[i].path;
      if (path.isNotEmpty) {
        final first = path.first;
        return (lat: first.lat, lon: first.lon);
      }

      final stop = legs[i].to;
      if (stop != null) {
        return (lat: stop.coord.lat, lon: stop.coord.lon);
      }
    }
    return null;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
