import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/fare_feedback_validator.dart';
import '../cubit/fare_feedback_cubit.dart';
import '../cubit/fare_feedback_state.dart';
import '../widgets/fare_chips_row.dart';
import '../widgets/fare_confirm_button.dart';
import '../widgets/fare_feedback_header.dart';
import '../widgets/fare_feedback_input.dart';

/// Premium Fare Feedback page for crowdsourcing fare data.
///
/// Thin Scaffold shell that creates a [FareFeedbackCubit] and composes
/// extracted widgets. All business logic lives in the Cubit; all
/// widget-level presentation lives in `widgets/`.
class FareFeedbackPage extends StatefulWidget {
  /// When true the user is updating the total route fare.
  final bool isTotalRoute;

  /// Human-readable leg name (e.g. "ميكروباص محرم بك").
  /// Only used when [isTotalRoute] is false.
  final String? legName;

  const FareFeedbackPage({
    super.key,
    required this.isTotalRoute,
    this.legName,
  });

  @override
  State<FareFeedbackPage> createState() => _FareFeedbackPageState();
}

class _FareFeedbackPageState extends State<FareFeedbackPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Handlers ────────────────────────────────────────────────────────

  void _handleChipSelected(int index, FareFeedbackCubit cubit) {
    final value = cubit.onChipSelected(index);
    _controller.text = value;
    // Dismiss the keyboard so the Confirm button is visible.
    FocusScope.of(context).unfocus();
  }

  void _handleConfirm(FareFeedbackCubit cubit) {
    final amount = cubit.onConfirm(_controller.text);
    if (amount == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thanks! Fare of ${FareFeedbackValidator.formatAmount(amount)} EGP recorded.',
        ),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );

    context.pop();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dynamicTitle = widget.isTotalRoute
        ? 'Update Total Fare'
        : 'تحديث أجرة: ${widget.legName ?? ''}';
    final isArabic = !widget.isTotalRoute;

    return BlocProvider(
      create: (_) => FareFeedbackCubit(),
      child: Builder(builder: (context) {
        final cubit = context.read<FareFeedbackCubit>();

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
              onPressed: () => context.pop(),
              tooltip: 'Back',
            ),
            title: Text(
              'Fare Feedback',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 8.h),
                        const FareFeedbackHeader(),
                        SizedBox(height: 20.h),
                        // Dynamic title
                        Align(
                          alignment: isArabic
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(
                            dynamicTitle,
                            textDirection:
                                isArabic ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Fare input — rebuilds only on errorText changes
                        BlocSelector<FareFeedbackCubit, FareFeedbackState,
                            String?>(
                          selector: (state) => state.errorText,
                          builder: (context, errorText) {
                            return FareFeedbackInput(
                              controller: _controller,
                              errorText: errorText,
                              onChanged: cubit.onInputChanged,
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
                        // Chips — rebuilds only on selectedChipIndex changes
                        BlocSelector<FareFeedbackCubit, FareFeedbackState,
                            int?>(
                          selector: (state) => state.selectedChipIndex,
                          builder: (context, selectedIndex) {
                            return FareChipsRow(
                              selectedIndex: selectedIndex,
                              onChipSelected: (i) =>
                                  _handleChipSelected(i, cubit),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),
                FareConfirmButton(
                  onPressed: () => _handleConfirm(cubit),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
