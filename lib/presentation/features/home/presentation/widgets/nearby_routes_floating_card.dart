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
    final title = _title();
    final nearest = routes.isNotEmpty ? routes.first : null;

    final nearestLine = nearest == null
        ? null
        : _routeLine(nearest.routeNameAr, nearest.routeShortNameAr);

    final otherCount = routes.length > 1 ? routes.length - 1 : 0;

    return Material(
      color: AppColors.searchInputBackground,
      elevation: 10,
      shadowColor: AppColors.shadow,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: routes.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 18.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    if (isMoving)
                      _subtleText('Moving…')
                    else if (isLoading)
                      _subtleText('Loading nearby routes…')
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
                        SizedBox(height: 4.h),
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
                              size: 14.r,
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

  String _routeLine(String routeNameAr, String? routeShortNameAr) {
    final name = routeNameAr.trim();
    final short = (routeShortNameAr ?? '').trim();
    if (short.isEmpty) return name;
    return '$name ($short)';
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
