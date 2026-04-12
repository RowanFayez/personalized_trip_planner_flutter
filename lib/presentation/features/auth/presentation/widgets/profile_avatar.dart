import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? email;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.email,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (email ?? '').trim().isNotEmpty
        ? (email!.trim()[0].toUpperCase())
        : 'U';

    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.searchInputBackground,
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: (size * 0.36).sp,
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.searchInputBackground,
            child: Text(
              initial,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: (size * 0.36).sp,
              ),
            ),
          );
        },
      ),
    );
  }
}
