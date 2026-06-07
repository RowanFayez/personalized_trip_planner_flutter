import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../features/routing/presentation/cubit/routing_cubit.dart';

/// Header showing "Route X of Y" with previous/next navigation arrows.
class RoutingHeaderRow extends StatelessWidget {
  final int total;
  final int index;

  const RoutingHeaderRow({
    super.key,
    required this.total,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutingCubit>();

    return Row(
      children: [
        Text(
          'Route ${index + 1} of $total',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: total <= 1 ? null : cubit.previousJourney,
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: total <= 1 ? null : cubit.nextJourney,
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
