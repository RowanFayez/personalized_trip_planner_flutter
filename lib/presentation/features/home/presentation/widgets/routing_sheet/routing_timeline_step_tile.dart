import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/domain/entities/routing_entities.dart';
import '../../utils/text_preference.dart';
import 'routing_route_chip.dart';

/// A single step in the journey timeline (walk, transit leg, transfer).
class RoutingTimelineStepTile extends StatelessWidget {
  final RouteLeg leg;
  final RouteLeg? nextLeg;
  final String? destinationName;
  final bool showTopConnector;
  final bool showBottomConnector;

  const RoutingTimelineStepTile({
    super.key,
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

    final title = _buildTitle(context);
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
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () {
                        final name = Uri.encodeComponent(_legDisplayName());
                        context.push(
                          '/fare-feedback?isTotalRoute=false&legName=$name',
                        );
                      },
                      child: Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 12.r,
                          color: AppColors.primaryTeal,
                        ),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _legDisplayName() {
    final modeLabel =
        TextPreference.preferred(leg.modeAr, leg.mode)?.trim() ?? '';
    final routeLabel =
        TextPreference.preferred(
          leg.routeShortNameAr,
          leg.routeShortName,
        )?.trim() ??
        '';

    if (modeLabel.isEmpty && routeLabel.isEmpty) {
      return leg.mode ?? 'Transit';
    }

    if (routeLabel.isNotEmpty &&
        (routeLabel == modeLabel || routeLabel.contains(modeLabel))) {
      return routeLabel;
    }

    if (modeLabel.isEmpty) return routeLabel;
    if (routeLabel.isEmpty) return modeLabel;

    return '$modeLabel $routeLabel';
  }

  Widget _buildTitle(BuildContext context) {
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
          RoutingRouteChip(label: routeLabel, mode: _normalizeMode(leg)),
        ] else if (modeLabel.isNotEmpty) ...[
          SizedBox(width: 8.w),
          RoutingRouteChip(label: modeLabel, mode: _normalizeMode(leg)),
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

    if (lines.isEmpty) {
      return TextPreference.preferred(leg.headsignAr, leg.headsign);
    }
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

  Color _modeColor(String mode) {
    final m = mode.trim().toLowerCase();
    if (m.contains('walk') || m == 'walking' || m.contains('transfer')) {
      return AppColors.walkColor;
    }
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
    if (m.contains('tonaya') || m.contains('taxi')) {
      return AppColors.tonayaColor;
    }
    return AppColors.routeLine;
  }
}
