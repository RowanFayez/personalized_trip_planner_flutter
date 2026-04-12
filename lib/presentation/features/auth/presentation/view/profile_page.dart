import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/auth_service.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/session_token_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await sl<AuthService>().signOut();
      // Navigation is handled by GoRouter redirect once auth state changes.
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthService>().currentUser;
    final authService = sl<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: user == null
            ? Center(
                child: Text(
                  'Not signed in.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeaderCard(user: user),
                    SizedBox(height: 18.h),
                    ProfileInfoCard(user: user),
                    SizedBox(height: 18.h),
                    SessionTokenSection(authService: authService),
                    SizedBox(height: 18.h),
                    SizedBox(
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: () => _signOut(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
