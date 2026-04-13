import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/constants/app_colors.dart';

/// Bottom action button for chat with AI
class MapActionButtons extends StatelessWidget {
  final VoidCallback onChatPressed;
  final VoidCallback onProfilePressed;
  final String? userPhotoUrl;
  final String? userEmail;

  const MapActionButtons({
    super.key,
    required this.onChatPressed,
    required this.onProfilePressed,
    this.userPhotoUrl,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(child: _ChatButton(onPressed: onChatPressed)),
        SizedBox(width: 12.w),
        _ProfileButton(
          onPressed: onProfilePressed,
          photoUrl: userPhotoUrl,
          email: userEmail,
        ),
      ],
    );
  }
}

class _ChatButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ChatButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryTeal,
                  size: 24.r,
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الاسطا',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Chat with AI',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? photoUrl;
  final String? email;

  const _ProfileButton({
    required this.onPressed,
    required this.photoUrl,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final size = 56.h;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.searchInputBackground,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(4.r),
            child: ClipOval(
              child: (photoUrl == null || photoUrl!.trim().isEmpty)
                  ? Container(
                      color: AppColors.surfaceDark,
                      child: Center(
                        child: Icon(
                          Icons.account_circle,
                          color: AppColors.textSecondary,
                          size: (size * 0.72).clamp(18.0, 40.0),
                        ),
                      ),
                    )
                  : Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) {
                        return Container(
                          color: AppColors.surfaceDark,
                          child: Center(
                            child: Icon(
                              Icons.account_circle,
                              color: AppColors.textSecondary,
                              size: (size * 0.72).clamp(18.0, 40.0),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
