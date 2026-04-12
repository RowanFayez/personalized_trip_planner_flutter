import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/auth_service.dart';

class SessionTokenSection extends StatefulWidget {
  final AuthService authService;

  const SessionTokenSection({super.key, required this.authService});

  @override
  State<SessionTokenSection> createState() => _SessionTokenSectionState();
}

class _SessionTokenSectionState extends State<SessionTokenSection> {
  bool _isLoading = false;

  Future<void> _copyIdToken({bool forceRefresh = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final token = await widget.authService.getIdToken(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      if (token == null || token.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No token available.')));
        return;
      }

      await Clipboard.setData(ClipboardData(text: token));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JWT (Firebase ID token) copied.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get token: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDecodedClaims() async {
    final token = await widget.authService.getIdToken();
    if (!mounted) return;
    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No token available.')));
      return;
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is not a valid JWT.')),
      );
      return;
    }

    String pretty;
    try {
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonObj = json.decode(decoded);
      pretty = const JsonEncoder.withIndent('  ').convert(jsonObj);
    } catch (_) {
      pretty = 'Failed to decode JWT payload.';
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text(
            'JWT Claims (payload)',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final email = (user?.email ?? '').trim();

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
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Session & Token',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            email.isNotEmpty
                ? 'Signed in as $email'
                : 'Signed in (email not available)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _ActionChip(
                label: _isLoading ? 'Copying…' : 'Copy JWT',
                icon: Icons.content_copy,
                onPressed: _isLoading ? null : () => _copyIdToken(),
              ),
              _ActionChip(
                label: 'Refresh token',
                icon: Icons.refresh,
                onPressed: _isLoading
                    ? null
                    : () => _copyIdToken(forceRefresh: true),
              ),
              if (kDebugMode)
                _ActionChip(
                  label: 'View claims',
                  icon: Icons.visibility,
                  onPressed: _isLoading ? null : _showDecodedClaims,
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'This JWT is the Firebase ID token that the app sends as Authorization: Bearer <token> to your backend.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.searchInputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 18.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
