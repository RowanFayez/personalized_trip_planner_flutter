import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/models/trip_metadata_model.dart';
import '../../data/services/crowdsourcing_permissions_service.dart';
import '../../data/services/trip_local_data_source.dart';
import '../cubit/contributions_cubit.dart';
import '../cubit/contributions_state.dart';
import '../cubit/recording_cubit.dart';
import '../cubit/recording_state.dart';
import '../widgets/contribution_list_item.dart';

class ContributionsPage extends StatelessWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ContributionsCubit(localDataSource: sl<TripLocalDataSource>())
                ..load(),
        ),
        BlocProvider(create: (_) => sl<RecordingCubit>()..init()),
      ],
      child: const _ContributionsView(),
    );
  }
}

class _ContributionsView extends StatefulWidget {
  const _ContributionsView();

  @override
  State<_ContributionsView> createState() => _ContributionsViewState();
}

class _ContributionsViewState extends State<_ContributionsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ContributionsCubit>().load();
    }
  }

  Future<void> _openReview(BuildContext context, String tripId) async {
    await context.push('${CrowdsourcingRoutes.review}/$tripId');
    if (!context.mounted) return;
    await context.read<ContributionsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<RecordingCubit, RecordingState>(
        listener: (context, state) {
          if (state is RecordingComplete) {
            context.read<ContributionsCubit>().load();
            if (state.shouldOpenReview) {
              unawaited(_openReview(context, state.tripMeta.tripId));
            }
          }
          if (state is RecordingInitial) {
            context.read<ContributionsCubit>().load();
          }
          if (state is RecordingError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: const Text(CrowdsourcingStrings.contributionsTitle),
          ),
          body: BlocBuilder<ContributionsCubit, ContributionsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: context.read<ContributionsCubit>().load,
                child: ListView(
                  padding: EdgeInsets.all(20.r),
                  children: [
                    _RecordingControlCard(state: state),
                    SizedBox(height: 16.h),
                    if (state.trips.isEmpty)
                      const _EmptyContributions()
                    else
                      for (final trip in state.trips) ...[
                        ContributionListItem(
                          trip: trip,
                          onTap: () => unawaited(
                            _openReview(context, trip.tripId),
                          ),
                          onAction: () => unawaited(
                            _openReview(context, trip.tripId),
                          ),
                          onDelete: () =>
                              _confirmDeleteTrip(context, trip.tripId),
                        ),
                        SizedBox(height: 12.h),
                      ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTrip(BuildContext context, String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(CrowdsourcingStrings.deleteTripQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(CrowdsourcingStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(CrowdsourcingStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ContributionsCubit>().deleteTrip(tripId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(CrowdsourcingStrings.tripDeleted)),
    );
  }
}

class _RecordingControlCard extends StatelessWidget {
  final ContributionsState state;

  const _RecordingControlCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final activeTrip = state.activeTrip;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: activeTrip == null ? AppColors.border : AppColors.primaryTeal,
        ),
      ),
      child: activeTrip == null
          ? _StartRecordingContent(canCreateTrip: state.canCreateTrip)
          : _ActiveRecordingContent(activeTrip: activeTrip),
    );
  }
}

class _StartRecordingContent extends StatefulWidget {
  final bool canCreateTrip;

  const _StartRecordingContent({required this.canCreateTrip});

  @override
  State<_StartRecordingContent> createState() => _StartRecordingContentState();
}

class _StartRecordingContentState extends State<_StartRecordingContent> {
  bool _isBatteryOptimized = false;

  @override
  void initState() {
    super.initState();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) {
      setState(() => _isBatteryOptimized = !status.isGranted);
    }
  }

  Future<void> _requestBatteryExemption() async {
    await Permission.ignoreBatteryOptimizations.request();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _checkBatteryOptimization();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isBatteryOptimized)
          GestureDetector(
            onTap: _requestBatteryExemption,
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.battery_alert, color: AppColors.warning, size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      CrowdsourcingStrings.batteryOptimizationWarning,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CrowdsourcingStrings.recordTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ElevatedButton(
              onPressed: widget.canCreateTrip ? () => _startRecording(context) : null,
              child: const Text(CrowdsourcingStrings.recordTrip),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startRecording(BuildContext context) async {
    if (!widget.canCreateTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(CrowdsourcingStrings.maxDraftsReached)),
      );
      return;
    }
    final recordingCubit = context.read<RecordingCubit>();
    final contributionsCubit = context.read<ContributionsCubit>();
    final allowed = await sl<CrowdsourcingPermissionsService>()
        .ensureAndroidPermissions(context);
    if (!allowed || !context.mounted) return;
    await recordingCubit.startRecording(null);
    if (!context.mounted) return;
    await contributionsCubit.load();
    if (!context.mounted) return;
    // Recheck battery optimization after permissions flow
    await _checkBatteryOptimization();
  }
}

class _ActiveRecordingContent extends StatelessWidget {
  final TripMetadataModel activeTrip;

  const _ActiveRecordingContent({required this.activeTrip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.radio_button_checked_rounded, color: AppColors.primaryTeal),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            _activeText(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        ElevatedButton.icon(
          onPressed: () => context.read<RecordingCubit>().stopRecording(),
          icon: const Icon(Icons.stop_rounded),
          label: const Text(CrowdsourcingStrings.arrived),
        ),
      ],
    );
  }

  String _activeText() {
    final startedAt = DateTime.tryParse(activeTrip.startedAt);
    if (startedAt == null) return CrowdsourcingStrings.silentRecordingTitle;
    final minutes = DateTime.now().difference(startedAt).inMinutes;
    return '${CrowdsourcingStrings.silentRecordingTitle} · $minutes min';
  }
}

class _EmptyContributions extends StatelessWidget {
  const _EmptyContributions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 36.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, color: AppColors.primaryTeal, size: 44.r),
          SizedBox(height: 12.h),
          Text(
            CrowdsourcingStrings.noContributions,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
