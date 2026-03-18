import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/route_preferences_service.dart';
import '../models/route_priority.dart';
import '../widgets/divider_line.dart';
import '../widgets/mode_row.dart';
import '../widgets/panel_divider.dart';
import '../widgets/preferences_panel.dart';
import '../widgets/priority_tile.dart';
import '../widgets/route_preferences_gradient.dart';
import '../widgets/route_preferences_header.dart';
import '../widgets/section_heading.dart';

class RoutePreferencesPage extends StatefulWidget {
  const RoutePreferencesPage({super.key});

  @override
  State<RoutePreferencesPage> createState() => _RoutePreferencesPageState();
}

class _RoutePreferencesPageState extends State<RoutePreferencesPage> {
  static const double _metersPerMinute = 80.0;

  final RoutePreferencesService _routePreferencesService =
      RoutePreferencesService();

  RoutePriority _priority = RoutePriority.fastest;
  double _maxWalkingMinutes = 30;

  bool _microbus = true;
  bool _tram = true;
  bool _minibus = false;
  bool _walking = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final saved = await _routePreferencesService.load();
    if (!mounted) return;

    setState(() {
      _maxWalkingMinutes =
          (saved.walkingCutoffMeters / _metersPerMinute).clamp(0, 60);

      _microbus = saved.restrictedModes.contains('microbus');
      _tram = saved.restrictedModes.contains('tram');
      _minibus = saved.restrictedModes.contains('minibus');
      _walking = saved.restrictedModes.contains('walking');
    });
  }

  Future<void> _applyPreferences() async {
    final restrictedModes = <String>[
      if (_microbus) 'microbus',
      if (_tram) 'tram',
      if (_minibus) 'minibus',
      if (_walking) 'walking',
    ];

    final walkingCutoffMeters = (_maxWalkingMinutes * _metersPerMinute).round();

    final current = await _routePreferencesService.load();
    final updated = current.copyWith(
      walkingCutoffMeters: walkingCutoffMeters,
      restrictedModes: restrictedModes.isEmpty
          ? RoutePreferencesService.defaultRestrictedModes
          : restrictedModes,
    );
    await _routePreferencesService.save(updated);
    if (!mounted) return;
    context.pop();
  }

  void _resetToDefault() {
    setState(() {
      _priority = RoutePriority.fastest;
      _maxWalkingMinutes =
          (RoutePreferencesService.defaultWalkingCutoffMeters /
                  _metersPerMinute)
              .clamp(0, 60);

      _microbus = RoutePreferencesService.defaultRestrictedModes.contains(
        'microbus',
      );
      _tram = RoutePreferencesService.defaultRestrictedModes.contains('tram');
      _minibus = RoutePreferencesService.defaultRestrictedModes.contains(
        'minibus',
      );
      _walking = RoutePreferencesService.defaultRestrictedModes.contains(
        'walking',
      );
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(8.5.w, 4.h, 8.5.w, 12.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoutePreferencesHeader(onClose: () => context.pop()),
                        SizedBox(height: 6.h),
                        Text(
                          'Prioritize by',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        PriorityTile(
                          width: 358.w,
                          height: 54,
                          label: 'Fastest Route',
                          selected: _priority == RoutePriority.fastest,
                          onTap: () =>
                              setState(() => _priority = RoutePriority.fastest),
                        ),
                        SizedBox(height: 5.h),
                        PriorityTile(
                          width: 358.w,
                          height: 54,
                          label: 'Cheapest Route',
                          selected: _priority == RoutePriority.cheapest,
                          onTap: () => setState(
                            () => _priority = RoutePriority.cheapest,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        PriorityTile(
                          width: 358.w,
                          height: 54,
                          label: 'Less Walking',
                          selected: _priority == RoutePriority.simplest,
                          onTap: () => setState(
                            () => _priority = RoutePriority.simplest,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        const DividerLine(),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Walking Time',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_maxWalkingMinutes.round()} min',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryTeal,
                            inactiveTrackColor: AppColors.surfaceDark,
                            thumbColor: AppColors.primaryTeal,
                            overlayColor: AppColors.primaryTeal.withValues(
                              alpha: 0.2,
                            ),
                            trackHeight: 2.5.h,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 10.r,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 60,
                            value: _maxWalkingMinutes.clamp(0, 60),
                            onChanged: (v) =>
                                setState(() => _maxWalkingMinutes = v),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        const SectionHeading(
                          text: 'Transport Modes',
                          fontSize: 17,
                        ),
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: 358.w,
                          child: PreferencesPanel(
                            child: Column(
                              children: [
                                ModeRow(
                                  iconAsset: 'assets/icons/microbus.svg',
                                  label: 'Microbus',
                                  value: _microbus,
                                  onChanged: (v) =>
                                      setState(() => _microbus = v),
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
                                  onChanged: (v) =>
                                      setState(() => _minibus = v),
                                ),
                                const PanelDivider(),
                                ModeRow(
                                  iconAsset: 'assets/icons/walking.svg',
                                  label: 'Walking',
                                  value: _walking,
                                  onChanged: (v) =>
                                      setState(() => _walking = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        const DividerLine(),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: _applyPreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: _resetToDefault,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.searchInputBackground,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27.r),
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
                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
