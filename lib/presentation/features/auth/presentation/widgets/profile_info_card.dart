import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/auth_service.dart';

class ProfileInfoCard extends StatelessWidget {
  final AuthService authService;

  const ProfileInfoCard({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final email = (authService.userEmail ?? '').trim();
    final uid = (authService.uid ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Email', value: email.isNotEmpty ? email : '-'),
          const Divider(height: 1, color: AppColors.divider),
          _InfoRow(label: 'UID', value: uid.isNotEmpty ? uid : '-'),
          const Divider(height: 1, color: AppColors.divider),
          _InfoRow(label: 'Provider', value: _providerLabel()),
        ],
      ),
    );
  }

  String _providerLabel() {
    final meta = authService.currentUser?.appMetadata;
    final value = meta == null ? null : meta['provider'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'supabase';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
