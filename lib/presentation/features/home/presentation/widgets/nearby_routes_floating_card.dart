import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/nearby_trips/domain/entities/nearby_route.dart';

class NearbyRoutesFloatingCard extends StatelessWidget {
  final String? streetName;
  final bool isMoving;
  final bool isLoading;
  final List<NearbyRoute> routes;
  final VoidCallback onTap;

  const NearbyRoutesFloatingCard({
    super.key,
    required this.streetName,
    required this.isMoving,
    required this.isLoading,
    required this.routes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent =
        (streetName ?? '').trim().isNotEmpty ||
        isMoving ||
        isLoading ||
        routes.isNotEmpty;
    if (!hasContent) return const SizedBox.shrink();

    final title = _title();
    final nearest = routes.isNotEmpty ? routes.first : null;

    final nearestLine = nearest == null
        ? null
        : _routeLine(nearest.routeNameAr, nearest.distanceMetersRounded);

    final otherCount = routes.length > 1 ? routes.length - 1 : 0;

    return Material(
      color: AppColors.searchInputBackground,
      elevation: 10,
      shadowColor: AppColors.shadow,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: routes.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 16.r,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (isMoving)
                      _subtleText('Moving…')
                    else if (isLoading)
                      _subtleText('Loading…')
                    else if (nearestLine != null) ...[
                      Text(
                        nearestLine,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (otherCount > 0) ...[
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                'و $otherCount خطوط أخرى',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textTertiary,
                              size: 13.r,
                            ),
                          ],
                        ),
                      ],
                    ] else
                      _subtleText('No nearby routes'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title() {
    if (isMoving) return 'Pin a street on the map';
    final name = (streetName ?? '').trim();
    if (name.isEmpty) return 'Tap the map to pin a street';
    return name;
  }

  String _routeLine(String routeNameAr, int? distanceMetersRounded) {
    final name = routeNameAr.trim();
    if (name.isEmpty) return '';

    final d = distanceMetersRounded;
    if (d == null) return name;
    return '$name • ${d}m';
  }

  Widget _subtleText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
