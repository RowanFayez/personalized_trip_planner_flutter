import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';

class CrowdsourcingPermissionsService {
  Future<bool> ensureAndroidPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final location = await Permission.locationWhenInUse.request();
    if (!location.isGranted) return false;

    await Permission.activityRecognition.request();
    if (!context.mounted) return false;

    final allowBackground = await _showBackgroundRationale(context);
    if (!allowBackground) return false;

    final background = await Permission.locationAlways.request();
    if (background.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    if (!background.isGranted) return false;

    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
    return true;
  }

  Future<bool> _showBackgroundRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(CrowdsourcingStrings.recordTitle),
          content: const Text(CrowdsourcingStrings.permissionsRationale),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(CrowdsourcingStrings.notNow),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(CrowdsourcingStrings.allow),
            ),
          ],
        ),
      ),
    );
    return result == true;
  }
}
