import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../features/routing/presentation/cubit/routing_state.dart';
import 'routing_sheet/routing_grab_handle.dart';
import 'routing_sheet/routing_sheet_content.dart';

export 'routing_sheet/routing_chat_row.dart';
export 'routing_sheet/routing_final_connection_tile.dart';
export 'routing_sheet/routing_first_connection_tile.dart';
export 'routing_sheet/routing_grab_handle.dart';
export 'routing_sheet/routing_header_row.dart';
export 'routing_sheet/routing_journey_summary.dart';
export 'routing_sheet/routing_route_chip.dart';
export 'routing_sheet/routing_sheet_content.dart';
export 'routing_sheet/routing_sheet_models.dart';
export 'routing_sheet/routing_timeline_arrival_tile.dart';
export 'routing_sheet/routing_timeline_step_tile.dart';

/// The draggable bottom sheet displayed while a route is being searched,
/// loaded, or shown.
///
/// This widget is a thin shell that provides the sheet chrome (rounded corners,
/// grab handle, close button) and delegates all content to [RoutingSheetContent].
class RoutingBottomSheet extends StatelessWidget {
  final VoidCallback? onClose;
  final String? requestedOriginName;
  final double? requestedOriginLatitude;
  final double? requestedOriginLongitude;
  final String? requestedDestinationName;
  final double? requestedDestinationLatitude;
  final double? requestedDestinationLongitude;

  const RoutingBottomSheet({
    super.key,
    this.onClose,
    this.requestedOriginName,
    this.requestedOriginLatitude,
    this.requestedOriginLongitude,
    this.requestedDestinationName,
    this.requestedDestinationLatitude,
    this.requestedDestinationLongitude,
  });

  Widget _buildHandleAndClose(BuildContext context) {
    return SizedBox(
      height: 28.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const RoutingGrabHandle(),
          Positioned(
            right: 0,
            child: SizedBox(
              width: 28.r,
              height: 28.r,
              child: IconButton(
                onPressed: () {
                  context.read<RoutingCubit>().clear();
                  onClose?.call();
                },
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textTertiary,
                  size: 20.r,
                ),
                tooltip: 'Close',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingCubit, RoutingState>(
      builder: (context, state) {
        if (state.status == RoutingStatus.initial) return const SizedBox();

        return DraggableScrollableSheet(
          minChildSize: 0.16,
          initialChildSize: 0.26,
          maxChildSize: 0.78,
          snap: true,
          snapSizes: const <double>[0.16, 0.26, 0.78],
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
                  _buildHandleAndClose(context),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: RoutingSheetContent(
                      state: state,
                      scrollController: scrollController,
                      requestedOriginName: requestedOriginName,
                      requestedOriginLatitude: requestedOriginLatitude,
                      requestedOriginLongitude: requestedOriginLongitude,
                      requestedDestinationName: requestedDestinationName,
                      requestedDestinationLatitude:
                          requestedDestinationLatitude,
                      requestedDestinationLongitude:
                          requestedDestinationLongitude,
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
