import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/custom_places_service.dart';
import '../../../../../core/services/saved_places_service.dart';
import '../../../../../core/services/user_activity_service.dart';
import '../../../../../core/storage/hive/core_hive_boxes.dart';
import '../../../../../core/storage/hive/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../map_picker/presentation/view/map_picker_page.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/google_sign_in_dialog.dart';
import '../../../home/presentation/widgets/custom_place_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = sl<AuthService>();
  late final SavedPlacesService _savedPlacesService = SavedPlacesService(
    authService: _authService,
  );
  final CustomPlacesService _customPlacesService =
      sl<CustomPlacesService>();
  final UserActivityService _userActivityService = sl<UserActivityService>();

  bool _isLoading = true;
  SavedPlace? _home;
  SavedPlace? _work;
  SavedPlace? _college;
  String? _lastSearch;
  LastRoute? _lastRoute;

  @override
  void initState() {
    super.initState();
    if (_authService.currentUser != null) {
      _load();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _load() async {
    if (_authService.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _home = null;
        _work = null;
        _college = null;
        _lastSearch = null;
        _lastRoute = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _savedPlacesService.getPlace(SavedPlaceType.home),
        _savedPlacesService.getPlace(SavedPlaceType.work),
        _savedPlacesService.getPlace(SavedPlaceType.college),
        _userActivityService.getLastSearch(),
        _userActivityService.getLastRoute(),
      ]);

      if (!mounted) return;
      setState(() {
        _home = results[0] as SavedPlace?;
        _work = results[1] as SavedPlace?;
        _college = results[2] as SavedPlace?;
        _lastSearch = results[3] as String?;
        _lastRoute = results[4] as LastRoute?;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndSave(SavedPlaceType type) async {
    final label = _labelForType(type);
    final result = await context.push<MapPickerResult>(
      '/map-picker/${type.name}',
    );
    if (!mounted) return;
    if (result == null) return;

    await _savedPlacesService.setPlace(
      type,
      SavedPlace(
        latitude: result.latitude,
        longitude: result.longitude,
        name: result.placeName,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label saved.')));
    await _load();
  }

  Future<void> _clearPlace(SavedPlaceType type) async {
    final label = _labelForType(type);
    await _savedPlacesService.clearPlace(type);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label deleted.')));
    await _load();
  }

  Future<void> _signOut() async {
    try {
      await sl<AuthService>().signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
      );
      return;
    }

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _authService.uid != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (signedIn)
                ProfileHeaderCard(authService: _authService)
              else
                _GuestHeader(
                  onSignIn: () {
                    showGoogleSignInDialog(context).then((_) {
                      if (!mounted) return;
                      setState(() {});
                      _load();
                    });
                  },
                ),

              if (signedIn) ...[
                SizedBox(height: 18.h),
                _SavedLocationsCard(
                  isLoading: _isLoading,
                  home: _home,
                  work: _work,
                  college: _college,
                  onSetHome: () => _pickAndSave(SavedPlaceType.home),
                  onSetWork: () => _pickAndSave(SavedPlaceType.work),
                  onSetCollege: () => _pickAndSave(SavedPlaceType.college),
                  onClearHome: () => _clearPlace(SavedPlaceType.home),
                  onClearWork: () => _clearPlace(SavedPlaceType.work),
                  onClearCollege: () => _clearPlace(SavedPlaceType.college),
                ),
                SizedBox(height: 18.h),
                _CustomPlacesCard(
                  userId: _authService.uid ?? '',
                  customPlacesService: _customPlacesService,
                ),
                SizedBox(height: 18.h),
                _RecentActivityCard(
                  isLoading: _isLoading,
                  lastSearch: _lastSearch,
                  lastRoute: _lastRoute,
                ),
                SizedBox(height: 18.h),
                _ContributionsCard(
                  onOpen: () => context.push(CrowdsourcingRoutes.contributions),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _labelForType(SavedPlaceType type) {
    return switch (type) {
      SavedPlaceType.home => 'Home',
      SavedPlaceType.work => 'Work',
      SavedPlaceType.college => 'College',
    };
  }
}

class _ContributionsCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _ContributionsCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: AppColors.primaryTeal, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              CrowdsourcingStrings.contributionsTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onOpen,
            child: const Text(CrowdsourcingStrings.openContributions),
          ),
        ],
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  final VoidCallback onSignIn;

  const _GuestHeader({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.searchInputBackground,
            child: Icon(
              Icons.account_circle,
              color: AppColors.textSecondary,
              size: 34.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not signed in',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Sign in with Google to sync your account.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          TextButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      ),
    );
  }
}

class _SavedLocationsCard extends StatelessWidget {
  final bool isLoading;
  final SavedPlace? home;
  final SavedPlace? work;
  final SavedPlace? college;
  final VoidCallback onSetHome;
  final VoidCallback onSetWork;
  final VoidCallback onSetCollege;
  final VoidCallback onClearHome;
  final VoidCallback onClearWork;
  final VoidCallback onClearCollege;

  const _SavedLocationsCard({
    required this.isLoading,
    required this.home,
    required this.work,
    required this.college,
    required this.onSetHome,
    required this.onSetWork,
    required this.onSetCollege,
    required this.onClearHome,
    required this.onClearWork,
    required this.onClearCollege,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saved locations',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          _SavedLocationRow(
            icon: Icons.home_outlined,
            title: 'Home',
            value: _formatPlace(home, isLoading),
            onSet: onSetHome,
            onClear: onClearHome,
            canClear: !isLoading && home != null,
          ),
          const Divider(height: 18, color: AppColors.divider),
          _SavedLocationRow(
            icon: Icons.work_outline,
            title: 'Work',
            value: _formatPlace(work, isLoading),
            onSet: onSetWork,
            onClear: onClearWork,
            canClear: !isLoading && work != null,
          ),
          const Divider(height: 18, color: AppColors.divider),
          _SavedLocationRow(
            icon: Icons.factory_outlined,
            title: 'College',
            value: _formatPlace(college, isLoading),
            onSet: onSetCollege,
            onClear: onClearCollege,
            canClear: !isLoading && college != null,
          ),
          SizedBox(height: 10.h),
          Text(
            'Tip: On the Home screen, choose a place using search (or the map button) then tap Home/Work/College to save it.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  static String _formatPlace(SavedPlace? place, bool isLoading) {
    if (isLoading) return 'Loading…';
    if (place == null) return 'Not set';
    final name = place.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Saved';
  }
}

class _SavedLocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onSet;
  final VoidCallback onClear;
  final bool canClear;

  const _SavedLocationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onSet,
    required this.onClear,
    required this.canClear,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = canClear;

    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onSet, child: Text(isSet ? 'Change' : 'Set')),
        if (canClear && isSet) ...[
          SizedBox(width: 6.w),
          TextButton(onPressed: onClear, child: const Text('Delete')),
        ],
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final bool isLoading;
  final String? lastSearch;
  final LastRoute? lastRoute;

  const _RecentActivityCard({
    required this.isLoading,
    required this.lastSearch,
    required this.lastRoute,
  });

  @override
  Widget build(BuildContext context) {
    final searchText = isLoading
        ? 'Loading…'
        : (lastSearch?.trim().isNotEmpty == true ? lastSearch!.trim() : '-');
    final routeText = isLoading
        ? 'Loading…'
        : (lastRoute == null ? '-' : '${lastRoute!.from} → ${lastRoute!.to}');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          _InfoLine(label: 'Last search', value: searchText),
          SizedBox(height: 10.h),
          _InfoLine(label: 'Last route', value: routeText),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomPlacesCard extends StatefulWidget {
  final String userId;
  final CustomPlacesService customPlacesService;

  const _CustomPlacesCard({
    required this.userId,
    required this.customPlacesService,
  });

  @override
  State<_CustomPlacesCard> createState() => _CustomPlacesCardState();
}

class _CustomPlacesCardState extends State<_CustomPlacesCard> {
  late Future<Box<dynamic>> _boxFuture;

  @override
  void initState() {
    super.initState();
    _boxFuture = HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
  }

  @override
  void didUpdateWidget(covariant _CustomPlacesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _boxFuture = HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    }
  }

  List<CustomPlace> _parsePlaces(Box<dynamic> box) {
    if (widget.userId.isEmpty) return const [];
    final key = CustomPlacesService.storageKeyFor(widget.userId);
    final raw = box.get(key);
    if (raw is! List) return const [];
    final places = <CustomPlace>[];
    for (final item in raw) {
      final place = CustomPlace.fromMap(item);
      if (place != null) places.add(place);
    }
    return places;
  }

  Future<void> _addPlace(BuildContext ctx) async {
    final places = await widget.customPlacesService.getCustomPlaces();
    if (places.length >= 10) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 custom places reached'),
        ),
      );
      return;
    }
    if (!ctx.mounted) return;
    await showCustomPlaceSheet(ctx, service: widget.customPlacesService);
  }

  Future<void> _editPlace(BuildContext ctx, CustomPlace place) async {
    await showCustomPlaceSheet(
      ctx,
      service: widget.customPlacesService,
      existing: place,
    );
  }

  Future<void> _deletePlace(CustomPlace place) async {
    await widget.customPlacesService.deleteCustomPlace(place.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();

    final customKey =
        CustomPlacesService.storageKeyFor(widget.userId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: FutureBuilder<Box<dynamic>>(
        future: _boxFuture,
        builder: (context, snapshot) {
          final box = snapshot.data;
          if (box == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Custom places',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }

          return ValueListenableBuilder<Box<dynamic>>(
            valueListenable: box.listenable(keys: [customKey]),
            builder: (context, value, _) {
              final places = _parsePlaces(value);
              final atCap = places.length >= 10;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Custom places',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (places.isEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      'No custom places yet. Add one below.',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 10.h),
                    for (int i = 0; i < places.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 16, color: AppColors.divider),
                      _CustomPlaceRow(
                        place: places[i],
                        onEdit: () => _editPlace(context, places[i]),
                        onDelete: () => _deletePlace(places[i]),
                      ),
                    ],
                  ],
                  SizedBox(height: 14.h),
                  OutlinedButton.icon(
                    onPressed: atCap ? null : () => _addPlace(context),
                    icon: Icon(Icons.add, size: 18.r),
                    label: Text(
                      atCap ? 'Limit reached (10/10)' : 'Add custom place',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      disabledForegroundColor: AppColors.textTertiary,
                      side: BorderSide(
                        color:
                            atCap ? AppColors.surfaceLight : AppColors.primaryTeal,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      textStyle: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _CustomPlaceRow extends StatelessWidget {
  final CustomPlace place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomPlaceRow({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.place_outlined, color: AppColors.textSecondary, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            place.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
        SizedBox(width: 4.w),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
