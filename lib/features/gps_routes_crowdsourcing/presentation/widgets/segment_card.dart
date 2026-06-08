import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../crowdsourcing/domain/fare_feedback_validator.dart';
import '../../../crowdsourcing/presentation/widgets/fare_chip.dart';
import '../../../crowdsourcing/presentation/widgets/fare_feedback_input.dart';
import '../../data/models/trip_segment_model.dart';
import 'mode_selector_sheet.dart';

class SegmentCard extends StatefulWidget {
  final TripSegmentModel segment;
  final ValueChanged<String?> onModeChanged;
  final ValueChanged<double?> onFareChanged;
  final VoidCallback onDelete;

  const SegmentCard({
    super.key,
    required this.segment,
    required this.onModeChanged,
    required this.onFareChanged,
    required this.onDelete,
  });

  @override
  State<SegmentCard> createState() => _SegmentCardState();
}

class _SegmentCardState extends State<SegmentCard> {
  late final TextEditingController _fareController;
  String? _fareError;

  @override
  void initState() {
    super.initState();
    _fareController = TextEditingController(text: _fareText());
  }

  @override
  void didUpdateWidget(covariant SegmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segment.fareEgp != widget.segment.fareEgp) {
      _fareController.text = _fareText();
    }
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _chooseMode() async {
    final mode = await ModeSelectorSheet.show(
      context: context,
      title: CrowdsourcingStrings.transit,
      selectedMode: widget.segment.mode,
    );
    widget.onModeChanged(mode);
  }

  void _setFareText(String value) {
    if (value.trim().isEmpty) {
      setState(() => _fareError = null);
      widget.onFareChanged(null);
      return;
    }
    final error = FareFeedbackValidator.validate(value);
    setState(() => _fareError = error);
    if (error == null) widget.onFareChanged(FareFeedbackValidator.parse(value));
  }

  void _selectPreset(int fare) {
    _fareController.text = fare.toString();
    _setFareText(_fareController.text);
  }

  @override
  Widget build(BuildContext context) {
    final color = CrowdsourcingModes.color(widget.segment.mode);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          right: BorderSide(color: color, width: 5.w),
        ),
      ),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CrowdsourcingStrings.segment} ${widget.segment.index + 1}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                tooltip: CrowdsourcingStrings.deleteSegment,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          OutlinedButton.icon(
            onPressed: _chooseMode,
            icon: const Icon(Icons.directions_bus_rounded),
            label: Text(
              '${CrowdsourcingModes.emoji(widget.segment.mode)} '
              '${CrowdsourcingModes.displayName(widget.segment.mode)}',
            ),
          ),
          SizedBox(height: 10.h),
          FareFeedbackInput(
            controller: _fareController,
            errorText: _fareError,
            onChanged: _setFareText,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: FareFeedbackValidator.presets
                .map(
                  (fare) => FareChip(
                    label: '$fare ${CrowdsourcingStrings.egp}',
                    isSelected: _fareController.text == fare.toString(),
                    onTap: () => _selectPreset(fare),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  String _fareText() {
    final fare = widget.segment.fareEgp;
    if (fare == null) return '';
    return FareFeedbackValidator.formatAmount(fare);
  }
}
