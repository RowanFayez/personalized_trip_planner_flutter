import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/saved_places_service.dart';
import '../../../../../core/services/user_activity_service.dart';
import '../../../map_picker/presentation/view/map_picker_page.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/google_sign_in_dialog.dart';

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
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                ProfileHeaderCard(user: user)
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

              if (user != null) ...[
                SizedBox(height: 18.h),
                _SavedLocationsCard(
                  isLoading: _isLoading,
                  home: _home,
                  work: _work,
                  college: _college,
                  onSetHome: () => _pickAndSave(SavedPlaceType.home),
                  onSetWork: () => _pickAndSave(SavedPlaceType.work),
                  onSetCollege: () => _pickAndSave(SavedPlaceType.college),
                ),
                SizedBox(height: 18.h),
                _RecentActivityCard(
                  isLoading: _isLoading,
                  lastSearch: _lastSearch,
                  lastRoute: _lastRoute,
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

  const _SavedLocationsCard({
    required this.isLoading,
    required this.home,
    required this.work,
    required this.college,
    required this.onSetHome,
    required this.onSetWork,
    required this.onSetCollege,
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
          ),
          const Divider(height: 18, color: AppColors.divider),
          _SavedLocationRow(
            icon: Icons.work_outline,
            title: 'Work',
            value: _formatPlace(work, isLoading),
            onSet: onSetWork,
          ),
          const Divider(height: 18, color: AppColors.divider),
          _SavedLocationRow(
            icon: Icons.factory_outlined,
            title: 'College',
            value: _formatPlace(college, isLoading),
            onSet: onSetCollege,
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

  const _SavedLocationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
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
        TextButton(onPressed: onSet, child: const Text('Set')),
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
