import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';

class CrowdsourcingPermissionsService {
  Future<bool> ensureAndroidPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final location = await Permission.location.request();
    if (!location.isGranted) {
      await _showOpenAppSettingsDialog(
        context,
        CrowdsourcingStrings.locationPermissionRequired,
      );
      return false;
    }
    if (!context.mounted) return false;

    final background = await Permission.locationAlways.request();
    if (!background.isGranted) {
      await _showOpenAppSettingsDialog(
        context,
        CrowdsourcingStrings.backgroundLocationRequired,
      );
      return false;
    }
    if (!context.mounted) return false;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return false;

    final activityRecognitionGranted = await _requestActivityRecognition();
    if (!activityRecognitionGranted && context.mounted) {
      _showSoftPermissionSnack(
        context,
        CrowdsourcingStrings.activityRecognitionOptional,
      );
    }
    if (!context.mounted) return false;

    await Permission.ignoreBatteryOptimizations.request();
    if (!context.mounted) return false;

    await Permission.notification.request();
    if (!context.mounted) return false;

    return _ensureGpsEnabled(context);
  }

  Future<bool> _requestActivityRecognition() async {
    try {
      final nativePermission = await FlutterActivityRecognition.instance
          .requestPermission();
      if (nativePermission == ActivityPermission.GRANTED) return true;
    } catch (_) {
      // Fall back to permission_handler below.
    }

    final permissionHandlerStatus = await Permission.activityRecognition
        .request();
    return permissionHandlerStatus.isGranted;
  }

  Future<bool> _ensureGpsEnabled(BuildContext context) async {
    if (await Geolocator.isLocationServiceEnabled()) return true;
    if (!context.mounted) return false;

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(CrowdsourcingStrings.gpsDisabledTitle),
          content: const Text(CrowdsourcingStrings.gpsDisabledForRecording),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(CrowdsourcingStrings.notNow),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(CrowdsourcingStrings.openGpsSettings),
            ),
          ],
        ),
      ),
    );
    if (shouldOpenSettings != true) return false;

    await Geolocator.openLocationSettings();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return Geolocator.isLocationServiceEnabled();
  }

  Future<void> _showOpenAppSettingsDialog(
    BuildContext context,
    String message,
  ) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(CrowdsourcingStrings.permissionsTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(CrowdsourcingStrings.notNow),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(openAppSettings());
              },
              child: const Text(CrowdsourcingStrings.openAppSettings),
            ),
          ],
        ),
      ),
    );
  }

  void _showSoftPermissionSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
