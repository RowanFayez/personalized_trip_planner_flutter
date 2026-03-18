import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../features/routing/presentation/cubit/routing_state.dart';
import 'routing_sheet/routing_grab_handle.dart';
import 'routing_sheet/routing_sheet_content.dart';

class RoutingBottomSheet extends StatelessWidget {
  const RoutingBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingCubit, RoutingState>(
      builder: (context, state) {
        if (state.status == RoutingStatus.initial) return const SizedBox();

        return DraggableScrollableSheet(
          minChildSize: 0.16,
          initialChildSize: 0.26,
          maxChildSize: 0.78,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.searchInputBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  const RoutingGrabHandle(),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: RoutingSheetContent(
                      state: state,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
