import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/saved_places_service.dart';
import '../../../../../core/storage/hive/core_hive_boxes.dart';
import '../../../../../core/storage/hive/hive_service.dart';

class QuickPlaceChips extends StatefulWidget {
  final String userId;
  final SavedPlacesService savedPlacesService;
  final ValueChanged<SavedPlaceType> onSelected;
  final VoidCallback onMore;

  const QuickPlaceChips({
    super.key,
    required this.userId,
    required this.savedPlacesService,
    required this.onSelected,
    required this.onMore,
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
    required bool isSet,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.searchInputBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSet ? AppColors.primaryTeal : AppColors.surfaceLight,
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
    );
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
              keys: [homeKey, workKey, collegeKey],
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

              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip(
                    icon: Icons.home_outlined,
                    title: _titleFor(SavedPlaceType.home),
                    subtitle: homeSubtitle,
                    isSet: homeIsSet,
                    onTap: () => widget.onSelected(SavedPlaceType.home),
                  ),
                  SizedBox(width: 10.w),
                  _chip(
                    icon: Icons.work_outline,
                    title: _titleFor(SavedPlaceType.work),
                    subtitle: workSubtitle,
                    isSet: workIsSet,
                    onTap: () => widget.onSelected(SavedPlaceType.work),
                  ),
                  SizedBox(width: 10.w),
                  _chip(
                    icon: Icons.factory_outlined,
                    title: _titleFor(SavedPlaceType.college),
                    subtitle: collegeSubtitle,
                    isSet: collegeIsSet,
                    onTap: () => widget.onSelected(SavedPlaceType.college),
                  ),
                  SizedBox(width: 10.w),
                  _chip(
                    icon: Icons.more_horiz,
                    title: 'More',
                    subtitle: '',
                    isSet: false,
                    onTap: widget.onMore,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
