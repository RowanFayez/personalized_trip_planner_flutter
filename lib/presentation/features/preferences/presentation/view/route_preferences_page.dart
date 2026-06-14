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
  static const List<_MainStreetOption> _mainStreetOptions = <_MainStreetOption>[
    _MainStreetOption(arabicLabel: 'كورنيش اسكندرية', id: 'Coastal'),
    _MainStreetOption(arabicLabel: 'شارع ابو قير', id: 'Abou Qir'),
    _MainStreetOption(arabicLabel: 'ترعة المحودية', id: 'Mahmoudia'),
  ];

  final RoutePreferencesService _routePreferencesService =
      RoutePreferencesService();

  RoutePriority _priority = RoutePriority.balanced;
  double _maxWalkingMinutes = RoutePreferencesService
      .defaultWalkingCutoffMinutes
      .toDouble();

  int _maxTransfers = RoutePreferencesService.defaultMaxTransfers;

  Set<String> _excludedMainStreetIds = <String>{};

  bool _microbus = true;
  bool _tomnaya = true;
  bool _minibus = true;
  bool _bus = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final saved = await _routePreferencesService.load();
    if (!mounted) return;

    setState(() {
      _maxTransfers = saved.maxTransfers
          .clamp(
            RoutePreferencesService.minTransfers,
            RoutePreferencesService.maxTransfersLimit,
          )
          .toInt();
      _maxWalkingMinutes = saved.walkingCutoffMinutes
          .clamp(
            RoutePreferencesService.minWalkingMinutes,
            RoutePreferencesService.maxWalkingMinutes,
          )
          .toDouble();

      _priority = _priorityFromString(saved.priority);

      _excludedMainStreetIds = saved.excludedMainStreets.toSet();

      // Toggles represent "allowed" modes.
      _microbus = !saved.restrictedModes.contains('microbus');
      _tomnaya = !saved.restrictedModes.contains('tomnaya');
      _minibus = !saved.restrictedModes.contains('minibus');
      _bus = !saved.restrictedModes.contains('bus');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  RoutePriority _priorityFromString(String value) {
    final v = value.trim().toLowerCase();
    return switch (v) {
      'fastest' => RoutePriority.fastest,
      'cheapest' => RoutePriority.cheapest,
      _ => RoutePriority.balanced,
    };
  }

  String _priorityToString(RoutePriority value) {
    return switch (value) {
      RoutePriority.fastest => 'fastest',
      RoutePriority.cheapest => 'cheapest',
      RoutePriority.balanced => 'balanced',
    };
  }

  void _toggleMainStreet(String id) {
    setState(() {
      final next = _excludedMainStreetIds.toSet();
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      _excludedMainStreetIds = next;
    });
  }

  Future<void> _applyPreferences() async {
    // Any transport mode that is OFF becomes restricted.
    final restrictedModes = <String>[
      if (!_microbus) 'microbus',
      if (!_tomnaya) 'tomnaya',
      if (!_minibus) 'minibus',
      if (!_bus) 'bus',
    ];

    final walkingCutoffMinutes = _maxWalkingMinutes
        .round()
        .clamp(
          RoutePreferencesService.minWalkingMinutes,
          RoutePreferencesService.maxWalkingMinutes,
        )
        .toInt();

    final current = await _routePreferencesService.load();
    final updated = current.copyWith(
      maxTransfers: _maxTransfers,
      walkingCutoffMinutes: walkingCutoffMinutes,
      restrictedModes: restrictedModes,
      priority: _priorityToString(_priority),
      excludedMainStreets: _excludedMainStreetIds.toList(growable: false),
    );
    await _routePreferencesService.save(updated);
    if (!mounted) return;
    context.pop(true);
  }

  void _resetToDefault() {
    setState(() {
      _priority = RoutePriority.balanced;
      _maxTransfers = RoutePreferencesService.defaultMaxTransfers;

      _maxWalkingMinutes = RoutePreferencesService.defaultWalkingCutoffMinutes
          .toDouble();

      _excludedMainStreetIds = <String>{};

      // Default is "no restrictions" => all modes allowed.
      _microbus = true;
      _tomnaya = true;
      _minibus = true;
      _bus = true;
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
              builder: (context, _) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 10.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RoutePreferencesHeader(
                        onClose: () => context.pop(false),
                      ),
                        SizedBox(height: 6.h),
                        Text(
                          'Prioritize by',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        PriorityTile(
                          width: double.infinity,
                          height: 46,
                          label: 'Fastest Route',
                          selected: _priority == RoutePriority.fastest,
                          onTap: () =>
                              setState(() => _priority = RoutePriority.fastest),
                        ),
                        SizedBox(height: 4.h),
                        PriorityTile(
                          width: double.infinity,
                          height: 46,
                          label: 'Cheapest Route',
                          selected: _priority == RoutePriority.cheapest,
                          onTap: () => setState(
                            () => _priority = RoutePriority.cheapest,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        PriorityTile(
                          width: double.infinity,
                          height: 46,
                          label: 'Balanced',
                          selected: _priority == RoutePriority.balanced,
                          onTap: () => setState(
                            () => _priority = RoutePriority.balanced,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        const DividerLine(),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Transfers',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _TransfersStepper(
                              value: _maxTransfers,
                              min: RoutePreferencesService.minTransfers,
                              max: RoutePreferencesService.maxTransfersLimit,
                              onChanged: (v) =>
                                  setState(() => _maxTransfers = v),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Walking Time',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_maxWalkingMinutes.round()} min',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryTeal,
                            inactiveTrackColor: AppColors.surfaceDark,
                            thumbColor: AppColors.primaryTeal,
                            overlayColor: AppColors.primaryTeal.withValues(
                              alpha: 0.2,
                            ),
                            trackHeight: 2.h,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 8.r,
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
                        SizedBox(height: 4.h),
                        const SectionHeading(
                          text: 'Transport Modes',
                          fontSize: 15,
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: double.infinity,
                          child: PreferencesPanel(
                            child: Column(
                              children: [
                                ModeRow(
                                  iconAsset: 'assets/icons/MICROBUS.png',
                                  label: 'Microbus',
                                  value: _microbus,
                                  onChanged: (v) =>
                                      setState(() => _microbus = v),
                                ),
                                const PanelDivider(),
                                ModeRow(
                                  iconAsset: 'assets/icons/tomnaya.png',
                                  label: 'Tomnaya',
                                  value: _tomnaya,
                                  onChanged: (v) =>
                                      setState(() => _tomnaya = v),
                                ),
                                const PanelDivider(),
                                ModeRow(
                                  iconAsset: 'assets/icons/minibus.png',
                                  label: 'Minibus',
                                  value: _minibus,
                                  onChanged: (v) =>
                                      setState(() => _minibus = v),
                                ),
                                const PanelDivider(),
                                ModeRow(
                                  iconAsset: 'assets/icons/BUS.png',
                                  label: 'Bus',
                                  value: _bus,
                                  onChanged: (v) => setState(() => _bus = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        const DividerLine(),
                        SizedBox(height: 8.h),
                        const SectionHeading(
                          text: 'Exclude streets :',
                          fontSize: 15,
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: double.infinity,
                          child: PreferencesPanel(
                            child: Padding(
                              padding: EdgeInsets.all(10.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6.w,
                                    runSpacing: 7.h,
                                    children: _mainStreetOptions
                                        .map(
                                          (opt) => _SelectableStreetChip(
                                            label: opt.arabicLabel,
                                            selected: _excludedMainStreetIds
                                                .contains(opt.id),
                                            onTap: () =>
                                                _toggleMainStreet(opt.id),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: ElevatedButton(
                            onPressed: _applyPreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: ElevatedButton(
                            onPressed: _resetToDefault,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.searchInputBackground,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Reset to Default',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                    ],
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

class _TransfersStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _TransfersStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canUp = value < max;
    final canDown = value > min;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 5.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: canUp ? () => onChanged(value + 1) : null,
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 15.r,
                  color: canUp
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              InkWell(
                onTap: canDown ? () => onChanged(value - 1) : null,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 15.r,
                  color: canDown
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainStreetOption {
  final String arabicLabel;
  final String id;

  const _MainStreetOption({required this.arabicLabel, required this.id});
}

class _SelectableStreetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableStreetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = label.trim();
    final backgroundColor = selected
        ? AppColors.tramColor.withValues(alpha: 0.22)
        : AppColors.searchInputBackground;
    final borderColor = selected ? AppColors.tramColor : AppColors.border;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (selected) ...[
              SizedBox(width: 4.w),
              Icon(Icons.close, size: 13.r, color: AppColors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
