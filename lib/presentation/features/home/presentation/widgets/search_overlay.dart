import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/mapbox_geocoding_service.dart';
import 'search_input_field.dart';
import 'preferences_button.dart';
import 'quick_place_chips.dart';
import '../../../../../core/services/saved_places_service.dart';

/// Top overlay containing search inputs and preferences button
class SearchOverlay extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocusNode;
  final FocusNode toFocusNode;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final ValueChanged<String> onFromSubmitted;
  final ValueChanged<String> onToSubmitted;
  final VoidCallback onFromTapped;
  final VoidCallback onToTapped;
  final bool showQuickPlaces;
  final bool showQuickPlacesUnderFrom;
  final String? signedInUserId;
  final SavedPlacesService savedPlacesService;
  final ValueChanged<SavedPlaceType> onQuickPlaceSelected;
  final VoidCallback onQuickPlaceMore;
  final List<MapboxPlaceSuggestion> fromSuggestions;
  final List<MapboxPlaceSuggestion> toSuggestions;
  final ValueChanged<MapboxPlaceSuggestion> onFromSuggestionSelected;
  final ValueChanged<MapboxPlaceSuggestion> onToSuggestionSelected;
  final bool showFromSuggestions;
  final bool showToSuggestions;
  final VoidCallback onPreferencesPressed;
  final VoidCallback onFromMapPressed;
  final VoidCallback onToMapPressed;

  const SearchOverlay({
    super.key,
    required this.fromController,
    required this.toController,
    required this.fromFocusNode,
    required this.toFocusNode,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onFromSubmitted,
    required this.onToSubmitted,
    required this.onFromTapped,
    required this.onToTapped,
    required this.showQuickPlaces,
    required this.showQuickPlacesUnderFrom,
    required this.signedInUserId,
    required this.savedPlacesService,
    required this.onQuickPlaceSelected,
    required this.onQuickPlaceMore,
    required this.fromSuggestions,
    required this.toSuggestions,
    required this.onFromSuggestionSelected,
    required this.onToSuggestionSelected,
    required this.showFromSuggestions,
    required this.showToSuggestions,
    required this.onPreferencesPressed,
    required this.onFromMapPressed,
    required this.onToMapPressed,
  });

  Widget _buildSuggestionsList({
    required List<MapboxPlaceSuggestion> suggestions,
    required ValueChanged<MapboxPlaceSuggestion> onSelected,
  }) {
    return Container(
      width: 358.w,
      constraints: BoxConstraints(maxHeight: 220.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, thickness: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return InkWell(
            onTap: () => onSelected(suggestion),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        color: AppColors.textSecondary,
                        size: 18.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          suggestion.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west,
                        color: AppColors.textTertiary,
                        size: 18.r,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    suggestion.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = signedInUserId;
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
              focusNode: fromFocusNode,
              hintText: 'From: من',
              svgAsset: 'assets/icons/from.svg',
              onTap: onFromTapped,
              onChanged: onFromChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: onFromSubmitted,
              suffixWidget: fromFocusNode.hasFocus
                  ? SvgPicture.asset('assets/icons/map.svg')
                  : null,
              onSuffixTap: onFromMapPressed,
            ),

            if (showQuickPlaces &&
                showQuickPlacesUnderFrom &&
                userId != null) ...[
              SizedBox(height: 10.h),
              QuickPlaceChips(
                userId: userId,
                savedPlacesService: savedPlacesService,
                onSelected: onQuickPlaceSelected,
                onMore: onQuickPlaceMore,
              ),
            ],

            if (showFromSuggestions && fromSuggestions.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _buildSuggestionsList(
                suggestions: fromSuggestions,
                onSelected: onFromSuggestionSelected,
              ),
            ],

            SizedBox(height: 10.h),

            // To field
            SearchInputField(
              controller: toController,
              focusNode: toFocusNode,
              hintText: 'To: إلى أين؟',
              svgAsset: 'assets/icons/to.svg',
              onTap: onToTapped,
              onChanged: onToChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: onToSubmitted,
              suffixWidget: toFocusNode.hasFocus
                  ? SvgPicture.asset('assets/icons/map.svg')
                  : null,
              onSuffixTap: onToMapPressed,
            ),

            if (showQuickPlaces &&
                !showQuickPlacesUnderFrom &&
                userId != null) ...[
              SizedBox(height: 10.h),
              QuickPlaceChips(
                userId: userId,
                savedPlacesService: savedPlacesService,
                onSelected: onQuickPlaceSelected,
                onMore: onQuickPlaceMore,
              ),
            ],

            if (showToSuggestions && toSuggestions.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _buildSuggestionsList(
                suggestions: toSuggestions,
                onSelected: onToSuggestionSelected,
              ),
            ],

            SizedBox(height: 10.h),

            // Preferences button
            PreferencesButton(onPressed: onPreferencesPressed),
          ],
        ),
      ),
    );
  }
}
