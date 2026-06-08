import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/models/trip_metadata_model.dart';
import '../../data/services/trip_local_data_source.dart';
import '../cubit/review_cubit.dart';
import '../cubit/review_state.dart';
import '../widgets/gpx_map_preview.dart';
import '../widgets/segment_card.dart';

class ReviewPage extends StatelessWidget {
  final TripMetadataModel tripMeta;

  const ReviewPage({super.key, required this.tripMeta});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewCubit(
        tripMeta: tripMeta,
        localDataSource: sl<TripLocalDataSource>(),
      )..init(),
      child: const _ReviewView(),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<ReviewCubit, ReviewState>(
        listenWhen: (previous, current) =>
            !previous.removedShortSegments && current.removedShortSegments,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed empty segments.')),
          );
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(title: const Text(CrowdsourcingStrings.reviewTitle)),
            body: Column(
              children: [
                SizedBox(
                  height: 0.35.sh,
                  child: GpxMapPreview(gpxFilePath: state.tripMeta.gpxFilePath),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      children: [
                        for (final segment in state.segments) ...[
                          SegmentCard(
                            segment: segment,
                            onModeChanged: (mode) => context
                                .read<ReviewCubit>()
                                .updateMode(segment.index, mode),
                            onFareChanged: (fare) => context
                                .read<ReviewCubit>()
                                .updateFare(segment.index, fare),
                            onDelete: () =>
                                _confirmDelete(context, segment.index),
                          ),
                          SizedBox(height: 12.h),
                        ],
                        _SubmitButton(state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(CrowdsourcingStrings.deleteSegmentQuestion),
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
    if (confirmed == true && context.mounted) {
      await context.read<ReviewCubit>().deleteSegment(index);
    }
  }
}

class _SubmitButton extends StatelessWidget {
  final ReviewState state;

  const _SubmitButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: CrowdsourcingUi.buttonHeight.h,
      child: ElevatedButton(
        onPressed: state.isSubmitting
            ? null
            : () async {
                await context.read<ReviewCubit>().submitForFutureUpload();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(CrowdsourcingStrings.pendingBackend),
                  ),
                );
                context.go(CrowdsourcingRoutes.contributions);
              },
        child: state.isSubmitting
            ? const CircularProgressIndicator()
            : Text(
                state.hasMissingModes
                    ? CrowdsourcingStrings.submitAnyway
                    : CrowdsourcingStrings.submitAndContribute,
              ),
      ),
    );
  }
}
