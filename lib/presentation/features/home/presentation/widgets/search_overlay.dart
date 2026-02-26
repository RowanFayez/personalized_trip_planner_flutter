import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/constants/app_colors.dart';
import 'search_input_field.dart';
import 'preferences_button.dart';

/// Top overlay containing search inputs and preferences button
class SearchOverlay extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onPreferencesPressed;

  const SearchOverlay({
    super.key,
    required this.fromController,
    required this.toController,
    required this.onPreferencesPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // From field
            SearchInputField(
              controller: fromController,
              hintText: 'From: من',
              icon: Icons.my_location,
              iconColor: AppColors.primaryTeal,
              onTap: () {
                // TODO: Open location search/autocomplete
              },
            ),

            SizedBox(height: 12.h),

            // To field
            SearchInputField(
              controller: toController,
              hintText: 'To: إلى أين؟',
              icon: Icons.location_on,
              iconColor: AppColors.accentRed,
              onTap: () {
                // TODO: Open destination search/autocomplete
              },
            ),

            SizedBox(height: 16.h),

            // Preferences button
            PreferencesButton(onPressed: onPreferencesPressed),
          ],
        ),
      ),
    );
  }
}
