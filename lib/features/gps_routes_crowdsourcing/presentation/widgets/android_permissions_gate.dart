import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../data/services/crowdsourcing_permissions_service.dart';

class AndroidPermissionsGate extends StatefulWidget {
  final Widget child;
  final CrowdsourcingPermissionsService permissionsService;

  const AndroidPermissionsGate({
    super.key,
    required this.child,
    required this.permissionsService,
  });

  @override
  State<AndroidPermissionsGate> createState() => _AndroidPermissionsGateState();
}

class _AndroidPermissionsGateState extends State<AndroidPermissionsGate> {
  bool _isChecking = true;
  bool _isAllowed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    final allowed = await widget.permissionsService.ensureAndroidPermissions(
      context,
    );
    if (allowed) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    if (!mounted) return;
    setState(() {
      _isAllowed = allowed;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isAllowed) return widget.child;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: AppColors.warning,
                  size: 42.r,
                ),
                SizedBox(height: 12.h),
                Text(
                  CrowdsourcingStrings.permissionError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isChecking = true);
                    unawaited(_check());
                  },
                  child: const Text(CrowdsourcingStrings.allow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
