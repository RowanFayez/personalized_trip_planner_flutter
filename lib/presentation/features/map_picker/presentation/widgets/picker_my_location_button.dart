import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

/// Floating "my location" button for the map picker.
class PickerMyLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PickerMyLocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundDark,
      borderRadius: BorderRadius.circular(14.r),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14.r),
        child: SizedBox(
          width: 48.r,
          height: 48.r,
          child: Icon(
            Icons.my_location,
            color: AppColors.primaryTeal,
            size: 24.r,
          ),
        ),
      ),
    );
  }
}
