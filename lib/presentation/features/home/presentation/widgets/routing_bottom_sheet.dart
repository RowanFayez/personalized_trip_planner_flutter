import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/animations/app_transitions.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/routing/domain/entities/routing_entities.dart';
import '../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../features/routing/presentation/cubit/routing_state.dart';
import '../utils/text_preference.dart';
import 'journey_summary_stats.dart';

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
          snap: true,
          snapSizes: const <double>[0.16, 0.26, 0.78],
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
                'No routes found.',
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

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          children: [
            const _ChatAboutRouteRow(),
            SizedBox(height: 10.h),
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
            ..._buildLegTiles(journey.legs, destinationName: destinationName),
            SizedBox(height: _safeBottomSpacing(context)),
          ],
        );

      case RoutingStatus.initial:
        return const SizedBox();
    }
  }

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

  List<Widget> _buildLegTiles(
    List<RouteLeg> legs, {
    required String? destinationName,
  }) {
    final tiles = <Widget>[];

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      final nextLeg = i + 1 < legs.length ? legs[i + 1] : null;
      final isFirst = i == 0;
      final isLastLeg = i == legs.length - 1;
      tiles.add(
        _TimelineStepTile(
          leg: leg,
          nextLeg: nextLeg,
          destinationName: destinationName,
          showTopConnector: !isFirst,
          showBottomConnector: true,
        ),
      );
      if (i != legs.length - 1) tiles.add(SizedBox(height: 10.h));
      if (isLastLeg) {
        tiles.add(SizedBox(height: 10.h));
        tiles.add(
          _TimelineArrivalTile(
            destinationName: destinationName,
            showTopConnector: true,
          ),
        );
      }
    }

    return tiles;
  }
}

class _ChatAboutRouteRow extends StatelessWidget {
  const _ChatAboutRouteRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Keep UX minimal: placeholder until chat screen is wired.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat: coming soon.')));
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 16.r,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Chat about this route',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
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

class _TimelineStepTile extends StatelessWidget {
  final RouteLeg leg;
  final RouteLeg? nextLeg;
  final String? destinationName;
  final bool showTopConnector;
  final bool showBottomConnector;

  const _TimelineStepTile({
    required this.leg,
    required this.nextLeg,
    required this.destinationName,
    required this.showTopConnector,
    required this.showBottomConnector,
  });

  @override
  Widget build(BuildContext context) {
    final mode = _normalizeMode(leg);
    final modeColor = _modeColor(mode);
    final leadingIcon = _leadingIcon(leg);

    final title = _title();
    final subtitle = _subtitle();
    final fare = leg.isTrip ? leg.fare : null;

    const dotSize = 30.0;
    final dotCenterY = 18.h;
    final dotTop = dotCenterY - dotSize / 2;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34.w,
            child: Stack(
              children: [
                if (showTopConnector)
                  Positioned(
                    left: (34.w - 2) / 2,
                    top: 0,
                    height: dotCenterY,
                    child: Container(width: 2, color: AppColors.surfaceLight),
                  ),
                if (showBottomConnector)
                  Positioned(
                    left: (34.w - 2) / 2,
                    top: dotCenterY,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.surfaceLight),
                  ),
                Positioned(
                  top: dotTop,
                  left: (34.w - dotSize) / 2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: AppColors.searchInputBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(leadingIcon, size: 16.r, color: modeColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.searchInputBackground,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        if (subtitle != null) ...[
                          SizedBox(height: 6.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (fare != null) ...[
                    SizedBox(width: 10.w),
                    Text(
                      '$fare EGP',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    if (leg.isWalk) {
      final target = _walkTargetName();
      final mins = leg.durationMinutes;
      final label = mins == null ? 'Walk' : 'Walk ($mins min)';

      return Text(
        target == null ? label : '$label to $target',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (leg.isTransfer) {
      final fromName =
          TextPreference.preferred(leg.fromTripNameAr, leg.fromTripName) ??
          leg.fromTripId;
      final toName =
          TextPreference.preferred(leg.toTripNameAr, leg.toTripName) ??
          leg.toTripId;
      final text = (fromName != null && toName != null)
          ? 'Get off at $fromName · Transfer to $toName'
          : 'Transfer';

      return Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final route = (leg.routeShortName ?? '').trim();
    final routeAr = (leg.routeShortNameAr ?? '').trim();
    final modeLabel = TextPreference.capitalize(
      TextPreference.preferred(leg.modeAr, leg.mode) ?? '',
    );

    final routeLabel = routeAr.isNotEmpty ? routeAr : route;

    return Row(
      children: [
        Text(
          'Take',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (routeLabel.isNotEmpty) ...[
          SizedBox(width: 8.w),
          _RouteChip(label: routeLabel, mode: _normalizeMode(leg)),
        ] else if (modeLabel.isNotEmpty) ...[
          SizedBox(width: 8.w),
          _RouteChip(label: modeLabel, mode: _normalizeMode(leg)),
        ],
      ],
    );
  }

  String? _subtitle() {
    if (leg.isWalk) {
      final mins = leg.durationMinutes;
      final meters = leg.distanceMeters;
      if (mins == null && meters == null) return null;
      final parts = <String>[];
      if (mins != null) parts.add('$mins min');
      if (meters != null) parts.add('$meters m');
      return parts.join(' • ');
    }

    if (leg.isTransfer) {
      final walk = leg.walkingDistanceMeters;
      if (walk == null) return null;
      return 'Walk $walk m';
    }

    final from = TextPreference.preferred(leg.from?.nameAr, leg.from?.name);
    final to = TextPreference.preferred(leg.to?.nameAr, leg.to?.name);
    final mins = leg.durationMinutes;
    final modeLabel = TextPreference.capitalize(
      TextPreference.preferred(leg.modeAr, leg.mode) ?? '',
    );

    final lines = <String>[];
    if (from != null && to != null) {
      lines.add('$from → $to');
    }
    final meta = <String>[];
    if (modeLabel.isNotEmpty) meta.add(modeLabel);
    if (mins != null) meta.add('$mins min');
    if (meta.isNotEmpty) lines.add(meta.join(' • '));

    if (lines.isEmpty)
      return TextPreference.preferred(leg.headsignAr, leg.headsign);
    return lines.join('\n');
  }

  String? _walkTargetName() {
    final next = nextLeg;
    if (next != null) {
      final nextFrom = TextPreference.preferred(
        next.from?.nameAr,
        next.from?.name,
      );
      if (nextFrom != null && nextFrom.trim().isNotEmpty) {
        return nextFrom.trim();
      }
    }
    final dest = destinationName;
    if (dest != null && dest.trim().isNotEmpty) return dest.trim();
    return null;
  }

  IconData _leadingIcon(RouteLeg leg) {
    if (leg.isWalk) return Icons.directions_walk;
    if (leg.isTransfer) return Icons.compare_arrows;

    final mode = (leg.mode ?? '').toLowerCase();
    if (mode.contains('tram') ||
        mode.contains('metro') ||
        mode.contains('subway') ||
        mode.contains('rail') ||
        mode.contains('line')) {
      return Icons.directions_subway;
    }
    if (mode.contains('bus') ||
        mode.contains('micro') ||
        mode.contains('mini')) {
      return Icons.directions_bus;
    }
    if (mode.contains('tonaya') || mode.contains('taxi')) {
      return Icons.local_taxi;
    }
    return Icons.directions_transit;
  }

  String _normalizeMode(RouteLeg leg) {
    if (leg.isWalk || leg.isTransfer) return 'walking';
    return (leg.mode ?? '').trim().toLowerCase();
  }

  String _modeLabel(String mode) {
    final m = mode.trim();
    if (m.isEmpty) return '';
    // Keep Arabic text as-is.
    final first = m.codeUnitAt(0);
    final isAsciiLetter =
        (first >= 65 && first <= 90) || (first >= 97 && first <= 122);
    if (!isAsciiLetter) return m;
    return m[0].toUpperCase() + m.substring(1);
  }

  Color _modeColor(String mode) {
    final m = mode.trim().toLowerCase();
    if (m.contains('walk') || m == 'walking' || m.contains('transfer')) {
      return AppColors.walkColor;
    }
    if (m.contains('micro'))
      return AppColors.tramColor; // requested: microbus blue
    if (m.contains('mini')) return AppColors.minibusColor;
    if (m.contains('bus')) return AppColors.busColor;
    if (m.contains('tram') ||
        m.contains('metro') ||
        m.contains('subway') ||
        m.contains('rail') ||
        m.contains('line')) {
      return AppColors.routeLine;
    }
    if (m.contains('tonaya') || m.contains('taxi'))
      return AppColors.tonayaColor;
    return AppColors.routeLine;
  }
}

class _TimelineArrivalTile extends StatelessWidget {
  final String? destinationName;
  final bool showTopConnector;

  const _TimelineArrivalTile({
    required this.destinationName,
    required this.showTopConnector,
  });

  @override
  Widget build(BuildContext context) {
    const dotSize = 30.0;
    final dotCenterY = 18.h;
    final dotTop = dotCenterY - dotSize / 2;
    final label = (destinationName ?? 'Destination').trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34.w,
            child: Stack(
              children: [
                if (showTopConnector)
                  Positioned(
                    left: (34.w - 2) / 2,
                    top: 0,
                    height: dotCenterY,
                    child: Container(width: 2, color: AppColors.surfaceLight),
                  ),
                Positioned(
                  top: dotTop,
                  left: (34.w - dotSize) / 2,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: AppColors.searchInputBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on,
                        size: 16.r,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.searchInputBackground,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'You have arrived at your destination.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  final String label;
  final String mode;

  const _RouteChip({required this.label, required this.mode});

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
    if (m.contains('tonaya') || m.contains('taxi'))
      return AppColors.tonayaColor;
    return AppColors.routeLine;
  }
}
