import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../models/route_priority.dart';
import '../widgets/divider_line.dart';
import '../widgets/mode_row.dart';
import '../widgets/panel_divider.dart';
import '../widgets/preferences_panel.dart';
import '../widgets/priority_tile.dart';
import '../widgets/route_preferences_gradient.dart';
import '../widgets/route_preferences_header.dart';
import '../widgets/section_heading.dart';
import '../widgets/toggle_row.dart';

class RoutePreferencesPage extends StatefulWidget {
  const RoutePreferencesPage({super.key});

  @override
  State<RoutePreferencesPage> createState() => _RoutePreferencesPageState();
}

class _RoutePreferencesPageState extends State<RoutePreferencesPage> {
  RoutePriority _priority = RoutePriority.fastest;
  double _maxWalkingMinutes = 30;

  bool _microbus = true;
  bool _tram = true;
  bool _minibus = false;
  bool _walking = true;

  bool _avoidTransfers = false;

  void _resetToDefault() {
    setState(() {
      _priority = RoutePriority.fastest;
      _maxWalkingMinutes = 30;
      _microbus = true;
      _tram = true;
      _minibus = false;
      _walking = true;
      _avoidTransfers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(child: const RoutePreferencesGradient()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 6.h),
                RoutePreferencesHeader(onClose: () => context.pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prioritize by',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        PriorityTile(
                          label: 'Fastest Route',
                          selected: _priority == RoutePriority.fastest,
                          onTap: () =>
                              setState(() => _priority = RoutePriority.fastest),
                        ),
                        SizedBox(height: 12.h),
                        PriorityTile(
                          label: 'Cheapest Route',
                          selected: _priority == RoutePriority.cheapest,
                          onTap: () => setState(
                            () => _priority = RoutePriority.cheapest,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        PriorityTile(
                          label: 'Simplest Route',
                          selected: _priority == RoutePriority.simplest,
                          onTap: () => setState(
                            () => _priority = RoutePriority.simplest,
                          ),
                        ),
                        SizedBox(height: 22.h),
                        const DividerLine(),
                        SizedBox(height: 18.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Walking Time',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_maxWalkingMinutes.round()} min',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryTeal,
                            inactiveTrackColor: AppColors.surfaceDark,
                            thumbColor: AppColors.primaryTeal,
                            overlayColor: AppColors.primaryTeal.withValues(
                              alpha: 0.2,
                            ),
                            trackHeight: 3.h,
                          ),
                          child: Slider(
                            min: 0,
                            max: 60,
                            value: _maxWalkingMinutes.clamp(0, 60),
                            onChanged: (v) =>
                                setState(() => _maxWalkingMinutes = v),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        const SectionHeading(text: 'Transport Modes'),
                        SizedBox(height: 10.h),
                        PreferencesPanel(
                          child: Column(
                            children: [
                              ModeRow(
                                iconAsset: 'assets/icons/microbus.svg',
                                label: 'Microbus',
                                value: _microbus,
                                onChanged: (v) => setState(() => _microbus = v),
                              ),
                              const PanelDivider(),
                              ModeRow(
                                iconAsset: 'assets/icons/tram.svg',
                                label: 'Tram',
                                value: _tram,
                                onChanged: (v) => setState(() => _tram = v),
                              ),
                              const PanelDivider(),
                              ModeRow(
                                iconAsset: 'assets/icons/minibus.svg',
                                label: 'Minibus',
                                value: _minibus,
                                onChanged: (v) => setState(() => _minibus = v),
                              ),
                              const PanelDivider(),
                              ModeRow(
                                iconAsset: 'assets/icons/walking.svg',
                                label: 'Walking',
                                value: _walking,
                                onChanged: (v) => setState(() => _walking = v),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18.h),
                        const DividerLine(),
                        SizedBox(height: 18.h),
                        const SectionHeading(text: 'General'),
                        SizedBox(height: 10.h),
                        PreferencesPanel(
                          child: ToggleRow(
                            leading: Icon(
                              Icons.swap_horiz,
                              color: AppColors.textPrimary,
                              size: 22.r,
                            ),
                            label: 'Avoid Transfers',
                            value: _avoidTransfers,
                            onChanged: (v) =>
                                setState(() => _avoidTransfers = v),
                          ),
                        ),
                        SizedBox(height: 26.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: () => context.pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: _resetToDefault,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.searchInputBackground,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Reset to Default',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
