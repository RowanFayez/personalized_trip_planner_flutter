import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../cubit/recording_cubit.dart';
import '../cubit/recording_state.dart';
import '../widgets/recording_action_bar.dart';
import '../widgets/recording_hud.dart';
import '../widgets/recording_map_canvas.dart';
import '../widgets/segment_transition_sheet.dart';
import '../widgets/start_mode_sheet.dart';

class CrowdsourcingMapPage extends StatefulWidget {
  const CrowdsourcingMapPage({super.key});

  @override
  State<CrowdsourcingMapPage> createState() => _CrowdsourcingMapPageState();
}

class _CrowdsourcingMapPageState extends State<CrowdsourcingMapPage> {
  bool _startGateShown = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final cubit = context.read<RecordingCubit>();
    await cubit.init();
    if (!mounted || _startGateShown || cubit.state is! RecordingInitial) return;
    _startGateShown = true;
    final mode = await StartModeSheet.show(context);
    if (!mounted) return;
    await cubit.startRecording(mode);
  }

  Future<void> _openTransitionSheet() async {
    final result = await SegmentTransitionSheet.show(context: context);
    if (!mounted || result == null) return;
    await context.read<RecordingCubit>().addSegmentTransition(
      mode: result.mode,
      fareEgp: result.fareEgp,
    );
  }

  RecordingInProgress? _visibleProgress(RecordingState state) {
    if (state is RecordingInProgress) return state;
    if (state is RecordingSmartPromptFired) return state.previous;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<RecordingCubit, RecordingState>(
        listener: (context, state) {
          if (state is RecordingComplete) {
            context.go(CrowdsourcingRoutes.review, extra: state.tripMeta);
          }
          if (state is RecordingError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final progress = _visibleProgress(state);
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Stack(
              children: [
                Positioned.fill(
                  child: RecordingMapCanvas(
                    recentPoints: progress?.recentPoints ?? const [],
                    segmentModes: progress?.segmentModes ?? const {},
                    pulsePrompt: state is RecordingSmartPromptFired,
                  ),
                ),
                if (progress != null)
                  RecordingHud(
                    modeDisplay: progress.currentModeDisplay,
                    mode: progress.currentMode,
                    elapsedSeconds: progress.elapsedSeconds,
                    distanceM: progress.distanceM,
                    isGpsLost: progress.isGpsLost,
                  ),
                if (progress != null)
                  RecordingActionBar(
                    onTransfer: _openTransitionSheet,
                    onArrived: context.read<RecordingCubit>().stopRecording,
                    onMinimize: () => context.go('/'),
                  ),
                if (state is RecordingGeneratingGpx) const _GeneratingOverlay(),
                if (state is RecordingOrphanFound)
                  _OrphanOverlay(
                    onResume: context
                        .read<RecordingCubit>()
                        .resumeOrphanRecording,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.overlay,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _OrphanOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const _OrphanOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.overlay,
      child: Center(
        child: ElevatedButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(CrowdsourcingStrings.startRecording),
        ),
      ),
    );
  }
}
