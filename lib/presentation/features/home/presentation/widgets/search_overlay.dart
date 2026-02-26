import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From field
            SearchInputField(
              controller: fromController,
              hintText: 'From: من',
              svgAsset: 'assets/icons/from.svg',
              onTap: () {},
            ),

            SizedBox(height: 10.h),

            // To field
            SearchInputField(
              controller: toController,
              hintText: 'To: إلى أين؟',
              svgAsset: 'assets/icons/to.svg',
              onTap: () {},
              suffixWidget: Icon(
                Icons.map_outlined,
                color: const Color(0xFF9AB8BC),
                size: 22.r,
              ),
            ),

            SizedBox(height: 10.h),

            // Preferences button
            PreferencesButton(onPressed: onPreferencesPressed),
          ],
        ),
      ),
    );
  }
}
