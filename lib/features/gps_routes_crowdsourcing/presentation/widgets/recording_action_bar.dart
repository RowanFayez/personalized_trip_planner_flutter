import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';

class RecordingActionBar extends StatelessWidget {
  final VoidCallback onTransfer;
  final VoidCallback onArrived;
  final VoidCallback onMinimize;

  const RecordingActionBar({
    super.key,
    required this.onTransfer,
    required this.onArrived,
    required this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, safeBottom + 20.h),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _IconButton(
                icon: Icons.swap_horiz_rounded,
                label: CrowdsourcingStrings.changedTransport,
                onPressed: onTransfer,
              ),
              SizedBox(width: 8.w),
              _IconButton(
                icon: Icons.flag_rounded,
                label: CrowdsourcingStrings.arrived,
                onPressed: onArrived,
                isPrimary: true,
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: onMinimize,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                color: AppColors.textPrimary,
                tooltip: CrowdsourcingStrings.minimize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _IconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = isPrimary ? ElevatedButton.icon : OutlinedButton.icon;
    return Expanded(
      child: SizedBox(
        height: CrowdsourcingUi.buttonHeight.h,
        child: button(
          onPressed: onPressed,
          icon: Icon(icon, size: 18.r),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
