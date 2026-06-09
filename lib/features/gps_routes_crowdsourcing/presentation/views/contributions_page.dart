import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/services/trip_local_data_source.dart';
import '../cubit/contributions_cubit.dart';
import '../cubit/contributions_state.dart';
import '../widgets/contribution_list_item.dart';

class ContributionsPage extends StatelessWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ContributionsCubit(localDataSource: sl<TripLocalDataSource>())
            ..load(),
      child: const _ContributionsView(),
    );
  }
}

class _ContributionsView extends StatelessWidget {
  const _ContributionsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
            if (state.trips.isEmpty) return const _EmptyContributions();
            return RefreshIndicator(
              onRefresh: context.read<ContributionsCubit>().load,
              child: ListView.separated(
                padding: EdgeInsets.all(20.r),
                itemCount: state.trips.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final trip = state.trips[index];
                  return ContributionListItem(
                    trip: trip,
                    onAction: () =>
                        context.push(CrowdsourcingRoutes.review, extra: trip),
                    onDelete: () => _confirmDeleteTrip(context, trip.tripId),
                  );
                },
              ),
            );
          },
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

class _EmptyContributions extends StatelessWidget {
  const _EmptyContributions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
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
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => context.push(CrowdsourcingRoutes.record),
              icon: const Icon(Icons.fiber_manual_record_rounded),
              label: const Text(CrowdsourcingStrings.startRecording),
            ),
          ],
        ),
      ),
    );
  }
}
