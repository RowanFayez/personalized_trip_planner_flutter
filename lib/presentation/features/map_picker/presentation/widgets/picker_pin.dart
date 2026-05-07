import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fixed pin in the centre of the map picker screen.
/// It includes a small bounce effect: the pin lifts when the map is moving.
class PickerPin extends StatelessWidget {
  const PickerPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Offset the pin so its bottom tip sits at the exact screen centre
      child: Padding(
        padding: EdgeInsets.only(bottom: 50.h),
        child: SvgPicture.asset(
          'assets/icons/interactive-search.svg',
          width: 46.w,
          height: 50.h,
        ),
      ),
    );
  }
}
