import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/nearby_trips/domain/entities/nearby_route.dart';

class NearbyRoutesBottomSheet extends StatelessWidget {
  final String? streetName;
  final bool isLoading;
  final bool hasLoadedSuccessfully;
  final List<NearbyRoute> routes;

  const NearbyRoutesBottomSheet({
    super.key,
    required this.streetName,
    required this.isLoading,
    required this.hasLoadedSuccessfully,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GrabHandle(),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(
                    'المسارات القريبة',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 22.r,
                    ),
                  ),
                ],
              ),
              if ((streetName ?? '').trim().isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    streetName!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ] else
                SizedBox(height: 6.h),
              Flexible(
                child: _RoutesList(
                  isLoading: isLoading,
                  hasLoadedSuccessfully: hasLoadedSuccessfully,
                  routes: routes,
                ),
              ),
            ],
          ),
        ),
      ),
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

class _RoutesList extends StatelessWidget {
  final bool isLoading;
  final bool hasLoadedSuccessfully;
  final List<NearbyRoute> routes;

  const _RoutesList({
    required this.isLoading,
    required this.hasLoadedSuccessfully,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(14.r),
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
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (routes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Text(
            hasLoadedSuccessfully
                ? 'لا توجد مسارات متاحة'
                : 'تعذر تحميل المسارات',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final sorted = routes.toList(growable: false)
      ..sort((a, b) => a.distanceMOrInf.compareTo(b.distanceMOrInf));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final route = sorted[index];
        final name = route.routeNameAr.trim();
        final short = (route.routeShortNameAr ?? '').trim();
        final distance = route.distanceMetersRounded;
        final distanceText = distance == null ? '' : '${distance}m';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
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
                    Icons.directions_transit,
                    color: Colors.white,
                    size: 18.r,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        if (short.isNotEmpty)
                          Expanded(
                            child: Text(
                              short,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (distanceText.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Text(
                            distanceText,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
