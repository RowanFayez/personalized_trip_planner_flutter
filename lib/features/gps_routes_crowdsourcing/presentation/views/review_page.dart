import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/models/trip_metadata_model.dart';
import '../../data/services/trip_finalizer_service.dart';
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
class ReviewLookupPage extends StatelessWidget {
  final String tripId;

  const ReviewLookupPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TripMetadataModel?>(
      future: sl<TripFinalizerService>().loadOrFinalizeForReview(tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final trip = snapshot.data;
        if (trip == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(title: const Text(CrowdsourcingStrings.reviewTitle)),
            body: const Center(
              child: Text(CrowdsourcingStrings.mapUnavailable),
            ),
          );
        }
        return ReviewPage(tripMeta: trip);
      },
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
            previous.error != current.error ||
            (!previous.removedShortSegments && current.removedShortSegments) ||
            (!previous.noValidSegments && current.noValidSegments) ||
            (!previous.submitSucceeded && current.submitSucceeded) ||
            (!previous.tripDeleted && current.tripDeleted),
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
            return;
          }
          if (state.noValidSegments) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(CrowdsourcingStrings.noValidSegments),
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(CrowdsourcingRoutes.contributions);
            }
            return;
          }
          if (state.submitSucceeded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(CrowdsourcingStrings.submittedSuccess),
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(CrowdsourcingRoutes.contributions);
            }
            return;
          }
          if (state.tripDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(CrowdsourcingStrings.tripDeleted)),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(CrowdsourcingRoutes.contributions);
            }
            return;
          }
          if (state.removedShortSegments) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(CrowdsourcingStrings.removedShortSegments),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              title: const Text(CrowdsourcingStrings.reviewTitle),
              actions: [
                IconButton(
                  onPressed: () => _confirmDeleteTrip(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: CrowdsourcingStrings.deleteTrip,
                ),
              ],
            ),
            body: Column(
              children: [
                GestureDetector(
                  onTap: () => _openFullMap(
                    context,
                    state.tripMeta.gpxFilePath,
                  ),
                  child: SizedBox(
                    height: 0.35.sh,
                    child: GpxMapPreview(
                      gpxFilePath: state.tripMeta.gpxFilePath,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      children: [
                        _RouteNameField(initialValue: state.tripMeta.routeName),
                        SizedBox(height: 12.h),
                        _ShareGpxButton(state: state),
                        SizedBox(height: 12.h),
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

  Future<void> _confirmDeleteTrip(BuildContext context) async {
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
    if (confirmed == true && context.mounted) {
      await context.read<ReviewCubit>().deleteTrip();
    }
  }

  void _openFullMap(BuildContext context, String? gpxFilePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenMapPreview(gpxFilePath: gpxFilePath),
      ),
    );
  }
}

class _RouteNameField extends StatefulWidget {
  final String? initialValue;

  const _RouteNameField({required this.initialValue});

  @override
  State<_RouteNameField> createState() => _RouteNameFieldState();
}

class _RouteNameFieldState extends State<_RouteNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant _RouteNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.initialValue ?? '';
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != nextValue) {
      _controller.text = nextValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: context.read<ReviewCubit>().updateRouteName,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: CrowdsourcingStrings.routeNameLabel,
        hintText: CrowdsourcingStrings.routeNameHint,
        prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
        filled: true,
        fillColor: AppColors.searchInputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}

class _ShareGpxButton extends StatelessWidget {
  final ReviewState state;

  const _ShareGpxButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: OutlinedButton.icon(
        onPressed: () => _share(context),
        icon: const Icon(Icons.ios_share_rounded),
        label: const Text(CrowdsourcingStrings.shareGpx),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final path = state.tripMeta.gpxFilePath;
    if (path == null || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(CrowdsourcingStrings.shareUnavailable)),
      );
      return;
    }
    await Share.shareXFiles(<XFile>[
      XFile(path),
    ], text: state.tripMeta.routeName ?? state.tripMeta.tripId);
  }
}

class _FullScreenMapPreview extends StatelessWidget {
  final String? gpxFilePath;

  const _FullScreenMapPreview({required this.gpxFilePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(CrowdsourcingStrings.reviewTitle),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: GpxMapPreview(gpxFilePath: gpxFilePath, interactive: true),
    );
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
              },
        child: state.isSubmitting
            ? SizedBox.square(
                dimension: 20.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                state.hasMissingModes
                    ? CrowdsourcingStrings.submitAnyway
                    : CrowdsourcingStrings.submitAndContribute,
              ),
      ),
    );
  }
}
