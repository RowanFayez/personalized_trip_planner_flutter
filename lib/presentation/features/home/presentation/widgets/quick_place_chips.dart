import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/custom_places_service.dart';
import '../../../../../core/services/saved_places_service.dart';
import '../../../../../core/storage/hive/core_hive_boxes.dart';
import '../../../../../core/storage/hive/hive_service.dart';
import 'custom_place_sheet.dart';

class QuickPlaceChips extends StatefulWidget {
  final String userId;
  final SavedPlacesService savedPlacesService;
  final CustomPlacesService customPlacesService;
  final ValueChanged<SavedPlaceType> onSelected;
  final SavedPlaceType? selectedType;
  final ValueChanged<CustomPlace> onCustomPlaceSelected;

  const QuickPlaceChips({
    super.key,
    required this.userId,
    required this.savedPlacesService,
    required this.customPlacesService,
    required this.onSelected,
    required this.selectedType,
    required this.onCustomPlaceSelected,
  });

  @override
  State<QuickPlaceChips> createState() => _QuickPlaceChipsState();
}

class _QuickPlaceChipsState extends State<QuickPlaceChips> {
  late Future<Box<dynamic>> _boxFuture;

  @override
  void initState() {
    super.initState();
    _boxFuture = HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    _warmUpMigrations();
  }

  @override
  void didUpdateWidget(covariant QuickPlaceChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // Box stays the same, but keys listened-to will change.
      // Keeping the same boxFuture avoids extra async work.
      _warmUpMigrations();
    }
  }

  void _warmUpMigrations() {
    // Ensure legacy (unscoped) saved places are migrated to user-scoped keys
    // as soon as the chips are shown.
    unawaited(widget.savedPlacesService.getPlace(SavedPlaceType.home));
    unawaited(widget.savedPlacesService.getPlace(SavedPlaceType.work));
    unawaited(widget.savedPlacesService.getPlace(SavedPlaceType.college));
  }

  static bool _isSet(dynamic value) {
    if (value is! Map) return false;
    final lat = value['lat'];
    final lng = value['lng'];
    return lat is num && lng is num;
  }

  static String? _name(dynamic value) {
    if (value is! Map) return null;
    final raw = value['name'];
    if (raw is! String) return null;
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String _titleFor(SavedPlaceType type) {
    return switch (type) {
      SavedPlaceType.home => 'Home',
      SavedPlaceType.work => 'Work',
      SavedPlaceType.college => 'College',
    };
  }

  static String _unsetSubtitleFor(SavedPlaceType type) {
    return switch (type) {
      SavedPlaceType.home => 'Set Home',
      SavedPlaceType.work => 'Set Work',
      SavedPlaceType.college => 'Set College',
    };
  }

  Widget _chip({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.searchInputBackground,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected ? AppColors.primaryTeal : AppColors.surfaceLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 17.r),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.sp,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the long-press context menu for a custom chip.
  void _showCustomChipMenu(BuildContext context, CustomPlace place) async {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppColors.surfaceLight),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18.r, color: AppColors.textPrimary),
              SizedBox(width: 8.w),
              Text(
                'Edit',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18.r, color: AppColors.accentRed),
              SizedBox(width: 8.w),
              Text(
                'Delete',
                style: TextStyle(color: AppColors.accentRed, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (result == 'edit') {
      await showCustomPlaceSheet(
        context,
        service: widget.customPlacesService,
        existing: place,
      );
    } else if (result == 'delete') {
      await widget.customPlacesService.deleteCustomPlace(place.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId.trim();
    if (userId.isEmpty) return const SizedBox.shrink();

    final homeKey = SavedPlacesService.storageKeyFor(
      userId: userId,
      type: SavedPlaceType.home,
    );
    final workKey = SavedPlacesService.storageKeyFor(
      userId: userId,
      type: SavedPlaceType.work,
    );
    final collegeKey = SavedPlacesService.storageKeyFor(
      userId: userId,
      type: SavedPlaceType.college,
    );
    final customKey = CustomPlacesService.storageKeyFor(userId);

    return SizedBox(
      width: 358.w,
      height: 46.h,
      child: FutureBuilder<Box<dynamic>>(
        future: _boxFuture,
        builder: (context, snapshot) {
          final box = snapshot.data;
          if (box == null) {
            return const SizedBox.shrink();
          }

          return ValueListenableBuilder<Box<dynamic>>(
            valueListenable: box.listenable(
              keys: [homeKey, workKey, collegeKey, customKey],
            ),
            builder: (context, value, _) {
              final homeValue = value.get(homeKey);
              final workValue = value.get(workKey);
              final collegeValue = value.get(collegeKey);

              final homeIsSet = _isSet(homeValue);
              final workIsSet = _isSet(workValue);
              final collegeIsSet = _isSet(collegeValue);

              final homeSubtitle = homeIsSet
                  ? (_name(homeValue) ?? 'Saved')
                  : _unsetSubtitleFor(SavedPlaceType.home);
              final workSubtitle = workIsSet
                  ? (_name(workValue) ?? 'Saved')
                  : _unsetSubtitleFor(SavedPlaceType.work);
              final collegeSubtitle = collegeIsSet
                  ? (_name(collegeValue) ?? 'Saved')
                  : _unsetSubtitleFor(SavedPlaceType.college);

              // Parse custom places from the box snapshot.
              final customRaw = value.get(customKey);
              final customPlaces = <CustomPlace>[];
              if (customRaw is List) {
                for (final item in customRaw) {
                  final place = CustomPlace.fromMap(item);
                  if (place != null) customPlaces.add(place);
                }
              }

              final selected = widget.selectedType;
              final atCap = customPlaces.length >= 10;

              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip(
                    icon: Icons.home_outlined,
                    title: _titleFor(SavedPlaceType.home),
                    subtitle: homeSubtitle,
                    isSelected: selected == SavedPlaceType.home,
                    onTap: () => widget.onSelected(SavedPlaceType.home),
                  ),
                  SizedBox(width: 10.w),
                  _chip(
                    icon: Icons.work_outline,
                    title: _titleFor(SavedPlaceType.work),
                    subtitle: workSubtitle,
                    isSelected: selected == SavedPlaceType.work,
                    onTap: () => widget.onSelected(SavedPlaceType.work),
                  ),
                  SizedBox(width: 10.w),
                  _chip(
                    icon: Icons.factory_outlined,
                    title: _titleFor(SavedPlaceType.college),
                    subtitle: collegeSubtitle,
                    isSelected: selected == SavedPlaceType.college,
                    onTap: () => widget.onSelected(SavedPlaceType.college),
                  ),

                  // Custom place chips
                  for (final place in customPlaces) ...[
                    SizedBox(width: 10.w),
                    Builder(
                      builder: (chipCtx) => _chip(
                        icon: Icons.place_outlined,
                        title: place.label,
                        subtitle: 'Custom',
                        isSelected: false,
                        onTap: () => widget.onCustomPlaceSelected(place),
                        onLongPress: () =>
                            _showCustomChipMenu(chipCtx, place),
                      ),
                    ),
                  ],

                  // "+ Add place" chip (hidden when at cap)
                  if (!atCap) ...[
                    SizedBox(width: 10.w),
                    InkWell(
                      onTap: () => showCustomPlaceSheet(
                        context,
                        service: widget.customPlacesService,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.searchInputBackground,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.surfaceLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppColors.primaryTeal,
                              size: 17.r,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Add place',
                              style: TextStyle(
                                color: AppColors.primaryTeal,
                                fontSize: 12.sp,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
