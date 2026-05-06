import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fixed bus-location pin used for the HomePage "Nearby Transit Routes" feature.
class NearbyBusLocationPin extends StatelessWidget {
  const NearbyBusLocationPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Offset the pin so its bottom tip sits at the exact screen centre
      child: Padding(
        padding: EdgeInsets.only(bottom: 56.h),
        child: SvgPicture.asset(
          'assets/icons/buslocation_icon.svg',
          width: 40.w,
          height: 56.h,
        ),
      ),
    );
  }
}
