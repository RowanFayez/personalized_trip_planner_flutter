import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../crowdsourcing/domain/fare_feedback_validator.dart';
import '../../../crowdsourcing/presentation/widgets/fare_chip.dart';
import '../../../crowdsourcing/presentation/widgets/fare_feedback_input.dart';
import 'mode_selector_sheet.dart';

typedef SegmentTransitionResult = ({String? mode, double? fareEgp});

class SegmentTransitionSheet extends StatefulWidget {
  final String title;
  final String? contextLine;

  const SegmentTransitionSheet({
    super.key,
    required this.title,
    this.contextLine,
  });

  static Future<SegmentTransitionResult?> show({
    required BuildContext context,
    String title = CrowdsourcingStrings.transitionTitle,
    String? contextLine,
  }) {
    return showModalBottomSheet<SegmentTransitionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          SegmentTransitionSheet(title: title, contextLine: contextLine),
    );
  }

  @override
  State<SegmentTransitionSheet> createState() => _SegmentTransitionSheetState();
}

class _SegmentTransitionSheetState extends State<SegmentTransitionSheet> {
  final TextEditingController _fareController = TextEditingController();
  String? _mode;
  String? _fareError;

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  void _selectPreset(int fare) {
    _fareController.text = fare.toString();
    setState(() => _fareError = null);
  }

  Future<void> _chooseMode() async {
    final selected = await ModeSelectorSheet.show(
      context: context,
      title: CrowdsourcingStrings.selectNextMode,
      selectedMode: _mode,
    );
    if (!mounted) return;
    setState(() => _mode = selected);
  }

  void _submit() {
    final fareText = _fareController.text.trim();
    final fare = fareText.isEmpty ? null : double.tryParse(fareText);
    if (fareText.isNotEmpty &&
        FareFeedbackValidator.validate(fareText) != null) {
      setState(() => _fareError = FareFeedbackValidator.validate(fareText));
      return;
    }
    Navigator.of(context).pop((mode: _mode, fareEgp: fare));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.contextLine != null) ...[
                SizedBox(height: 8.h),
                Text(
                  widget.contextLine!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                CrowdsourcingStrings.previousFare,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 8.h),
              FareFeedbackInput(
                controller: _fareController,
                errorText: _fareError,
                onChanged: (_) => setState(() => _fareError = null),
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
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: _chooseMode,
                child: Text(CrowdsourcingModes.displayName(_mode)),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submit,
                      child: const Text(CrowdsourcingStrings.skip),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text(CrowdsourcingStrings.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
