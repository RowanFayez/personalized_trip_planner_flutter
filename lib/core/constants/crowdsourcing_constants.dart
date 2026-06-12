import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_strings.dart';

class CrowdsourcingRoutes {
  CrowdsourcingRoutes._();

  static const String record = '/crowdsourcing/record';
  static const String review = '/crowdsourcing/review';
  static const String contributions = '/crowdsourcing/contributions';
}

class CrowdsourcingHiveKeys {
  CrowdsourcingHiveKeys._();

  static const String activeTrip = 'active_trip';
  static const String tripMetaKeys = 'trip_meta_keys';
  static const String gpsPrefix = 'gps_pts_';
  static const String transfersPrefix = 'transfers_';
  static const String tripMetaPrefix = 'trip_meta_';
  static const String pendingReviewTripId = 'pending_review_trip_id';
}

class TripStatuses {
  TripStatuses._();

  static const String recording = 'recording';
  static const String paused = 'paused';
  static const String gpsLost = 'gps_lost';
  static const String stopped = 'stopped';
  static const String pendingReview = 'pending_review';
  static const String pendingUpload = 'pending_upload';
  static const String uploaded = 'uploaded';
  static const String uploadFailed = 'upload_failed';
}

class TransferResponses {
  TransferResponses._();

  static const String confirmed = 'confirmed';
  static const String rejected = 'rejected';
  static const String ignored = 'ignored';
}

class SegmentConfidence {
  SegmentConfidence._();

  static const String userConfirmed = 'user_confirmed';
  static const String unknown = 'unknown';
}

class CrowdsourcingIpc {
  CrowdsourcingIpc._();

  static const String startTrip = 'start_trip';
  static const String stopTrip = 'stop_trip';
  static const String stopService = 'stopService';
  static const String addSegment = 'add_segment';
  static const String confirmTransfer = 'confirm_transfer';
  static const String rejectTransfer = 'reject_transfer';
  static const String pauseTrip = 'pause_trip';
  static const String resumeTrip = 'resume_trip';
  static const String gpsPoint = 'gps_point';
  static const String potentialTransfer = 'potential_transfer';
  static const String segmentSplitConfirmed = 'segment_split_confirmed';
  static const String transferRejected = 'transfer_rejected';
  static const String tripAutoPaused = 'trip_auto_paused';
  static const String gpsLost = 'gps_lost';
  static const String gpsRestored = 'gps_restored';
  static const String tripStopped = 'trip_stopped';
  static const String bringToForeground = 'bring_to_foreground';
  static const String notificationTransferRequested =
      'notification_transfer_requested';
  static const String showModeSelector = 'show_mode_selector';
  static const String setCurrentSegmentMode = 'set_current_segment_mode';
}

class CrowdsourcingPayloadKeys {
  CrowdsourcingPayloadKeys._();

  static const String tripId = 'tripId';
  static const String mode = 'mode';
  static const String fareEgp = 'fareEgp';
  static const String detectedAt = 'detectedAt';
  static const String lat = 'lat';
  static const String lon = 'lon';
  static const String segmentIndex = 'segmentIndex';
  static const String distanceM = 'distanceM';
  static const String elapsedSeconds = 'elapsedSeconds';
  static const String isGpsLost = 'isGpsLost';
  static const String type = 'type';
}

class CrowdsourcingNotifications {
  CrowdsourcingNotifications._();

  static const int recordingId = 888;
  static const int smartPromptId = 889;
  static const int stationaryId = 890;
  static const int reviewReadyId = 891;
  static const int storageFullId = 892;
  static const int permissionStoppedId = 893;
  static const String recordingChannelId = 'yastaa_recording';
  static const String promptChannelId = 'yastaa_smart_prompt';
  static const String actionTransfer = 'transfer';
  static const String actionArrived = 'arrived';
  static const String actionConfirmTransfer = 'confirm_transfer';
  static const String actionRejectTransfer = 'reject_transfer';
  static const String actionStop = 'stop';
  static const String actionContinue = 'continue';
  static const String reviewReadyPayload = 'review_ready';
  static const String reviewReadyPayloadType = 'review_ready';
}

class CrowdsourcingTiming {
  CrowdsourcingTiming._();

  static const Duration minPointInterval = Duration(seconds: 10);
  static const Duration flushInterval = Duration(seconds: 30);
  static const Duration gpsLostAfter = Duration(seconds: 60);
  static const Duration transferDebounce = Duration(seconds: 60);
  static const Duration promptCooldown = Duration(seconds: 180);
  static const Duration promptExpiresAfter = Duration(minutes: 5);
  static const Duration stationaryAfter = Duration(minutes: 15);
  static const Duration maxRecordingDuration = Duration(hours: 2);
}

class CrowdsourcingLimits {
  CrowdsourcingLimits._();

  static const int gpsBufferMax = 50;
  static const int liveMapPointMax = 500;
  static const int speedWindowMax = 10;
  static const double gpsRecordingAccuracyMaxM = 50;
  static const double gpxAccuracyMaxM = 30;
  static const double gpxStillAccuracyMaxM = 15;
  static const double staticDriftMinDistanceM = 12;
  static const double activeVelocityMs = 0.8;
  static const double stationaryResumeVelocityMs = 1.5;
  static const double stationaryRadiusM = 5;
  static const double impossibleTransitSpeedMs = 38.89;
  static const int privacyFuzzingMinutes = 3;
  static const double privacyFuzzingDistanceM = 200;
  static const int maxSavedTrips = 5;
}

class CrowdsourcingGpx {
  CrowdsourcingGpx._();

  static const String appVersion = '1.0.0';
  static const String deviceOs = 'android';
  static const String creator = 'Yastaa-Android';
  static const String namespace = 'http://www.topografix.com/GPX/1/1';
  static const String extensionNamespace =
      'http://yastaa.app/gpx/extensions/v1';
  static const String folderName = 'crowdsourcing';
}

class CrowdsourcingUi {
  CrowdsourcingUi._();

  static const double screenPadding = 20;
  static const double cardRadius = 8;
  static const double controlRadius = 8;
  static const double iconSize = 20;
  static const double smallGap = 8;
  static const double gap = 12;
  static const double largeGap = 18;
  static const double buttonHeight = 52;
  static const double bottomBarHeight = 88;
  static const double mapPreviewHeightFactor = 0.35;
  static const double routeWidth = 6;
  static const double pulseSize = 58;
}

class CrowdsourcingStrings {
  CrowdsourcingStrings._();

  static const String recordTitle = 'تسجيل رحلة';
  static const String reviewTitle = 'مراجعة الرحلة';
  static const String contributionsTitle = 'مساهماتي';
  static const String startRecording = 'ابدأ تسجيل رحلة';
  static const String openContributions = 'افتح';
  static const String startWithoutMode = 'ابدأ من غير تحديد';
  static const String changedTransport = 'غيّرت المواصلة';
  static const String arrived = 'وصلت ✓';
  static const String minimize = '−';
  static const String selectCurrentMode = 'ما الوسيلة اللي بتركبها دلوقتي؟';
  static const String selectNextMode = 'بتركب إيه دلوقتي؟';
  static const String transitionTitle = 'بدّلت المواصلة؟';
  static const String previousFare = 'أجرة الرحلة اللي فاتت؟';
  static const String skip = 'تخطي';
  static const String save = 'حفظ';
  static const String submitAndContribute = 'Submit & Contribute';
  static const String submitAnyway = 'Submit Anyway';
  static const String recordTrip = '+ Record Trip';
  static const String routeNameLabel = 'اسم الخط';
  static const String routeNameHint = 'مثال: عصافرة - محطة مصر';
  static const String shareGpx = 'Share GPX';
  static const String shareUnavailable = 'ملف GPX مش جاهز لسه';
  static const String submittedSuccess = 'تم إرسال الرحلة التجريبية بنجاح';
  static const String maxDraftsReached =
      'مسموح لحد 5 رحلات محفوظة. امسح رحلة قديمة الأول.';
  static const String silentRecordingTitle = 'Yastaa — جاري التسجيل';
  static const String silentRecordingBody =
      'التسجيل شغال، تقدر توقفه من هنا أو من الإشعار.';
  static const String pendingBackend =
      'تم حفظ المساهمة محلياً وجاهزة للإرسال لما الباكند يبقى متاح.';
  static const String noValidSegments = 'الرحلة دي مفيهاش بيانات كافية للإرسال';
  static const String mapUnavailable = 'الخريطة مش متاحة لهذه الرحلة';
  static const String removedShortSegments = 'تم حذف الأجزاء الفارغة من الرحلة';
  static const String deleteTrip = 'حذف الرحلة';
  static const String deleteTripQuestion = 'تحذف الرحلة دي؟';
  static const String tripDeleted = 'تم حذف الرحلة';
  static const String noContributions = 'مفيش مساهمات لحد دلوقتي';
  static const String recordingNotificationTitle = 'Yastaa — جاري التسجيل';
  static const String recordingNotificationInitialBody =
      'الوقت: 00:00:00 • المسافة: 0.0 كم';
  static const String unspecifiedMode = 'وسيلة غير محددة';
  static const String smartPromptTitle = 'Yastaa — تبديل مواصلة؟';
  static const String smartPromptBody =
      'حسّينا إنك نزلت وركبت مواصلة تانية. هل غيّرت فعلاً؟';
  static const String smartPromptYes = 'أيوه، غيّرت';
  static const String smartPromptNo = 'لأ، زحمة بس';
  static const String stillRecording = 'Yastaa — لسه بتسجل؟ وصلت؟';
  static const String gpsLost = 'GPS اتقفل — التسجيل وقف مؤقتاً.';
  static const String preparingTripData = 'جاري تجهيز بيانات الرحلة...';
  static const String reviewReadyTitle = 'Yastaa — الرحلة اتسجلت ✓';
  static const String reviewReadyBody = 'افتح التطبيق لمراجعتها وإرسالها';
  static const String tripSavedReviewTitle = 'Yastaa — Trip saved!';
  static const String tripSavedReviewBody = 'Tap to review.';
  static const String gpsDisabledTitle = 'Yastaa — GPS مقفول';
  static const String gpsDisabledBody =
      'وقفنا التسجيل مؤقتا. افتح GPS عشان نكمل.';
  static const String splitPromptTitle = 'Yastaa — نزلت وبتمشي؟';
  static const String splitPromptBody =
      'لو غيرت المواصلة دوس هنا عشان نفصل الجزء. لو تجاهلت الرسالة هنكمل نفس المواصلة.';
  static const String splitPromptAction = 'افصل المواصلة';
  static const String storageFullTitle = 'Yastaa — تم إيقاف التسجيل';
  static const String storageFullBody =
      'تم إيقاف التسجيل لامتلاء مساحة التخزين';
  static const String locationPermissionStoppedTitle =
      'Yastaa — تم إيقاف التسجيل';
  static const String locationPermissionStoppedBody =
      'تم إيقاف التسجيل لعدم وجود صلاحية الموقع';
  static const String permissionsTitle = 'صلاحيات التسجيل';
  static const String locationPermissionRequired =
      'Yastaa محتاج صلاحية الموقع عشان يبدأ تسجيل الرحلة.';
  static const String backgroundLocationRequired =
      'Yastaa محتاج صلاحية الموقع في الخلفية عشان التسجيل يكمل والشاشة مقفولة.';
  static const String activityRecognitionOptional =
      'هتكمل التسجيل عادي، بس اقتراحات تبديل المواصلة مش هتظهر من غير صلاحية النشاط.';
  static const String gpsDisabledForRecording =
      'افتح GPS عشان Yastaa يقدر يسجل الرحلة بدقة.';
  static const String openGpsSettings = 'فتح إعدادات GPS';
  static const String openAppSettings = 'فتح إعدادات التطبيق';
  static const String permissionsRationale =
      'Yastaa محتاج يوصل للموقع وهو في الخلفية عشان يكمل تسجيل رحلتك.';
  static const String allow = 'السماح';
  static const String notNow = 'مش دلوقتي';
  static const String settings = 'الإعدادات';
  static const String permissionError =
      'محتاجين صلاحيات الموقع في الخلفية عشان التسجيل يشتغل بأمان.';
  static const String pendingReviewBadge = 'Ready to Submit';
  static const String pendingUploadBadge = 'Waiting for backend';
  static const String uploadedBadge = 'Uploaded';
  static const String uploadFailedBadge = 'Retry Upload';
  static const String edit = 'Edit';
  static const String retry = 'Retry';
  static const String submit = 'Submit';
  static const String deleteSegment = 'Delete segment';
  static const String deleteSegmentQuestion = 'Delete this segment?';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String segment = 'Segment';
  static const String transit = 'Transit';
  static const String fare = 'Fare';
  static const String egp = 'EGP';
}

class CrowdsourcingModes {
  CrowdsourcingModes._();

  static const List<String?> selectable = <String?>[
    AppStrings.modeMicrobus,
    AppStrings.modeMinibus,
    AppStrings.modeTomnaya,
    AppStrings.modeBus,
    null,
  ];

  static String displayName(String? mode) {
    return switch (mode) {
      AppStrings.modeMicrobus => 'ميكروباص',
      AppStrings.modeMinibus => 'ميني باص',
      AppStrings.modeTomnaya => 'تمنية',
      AppStrings.modeTonaya => 'تمنية',
      AppStrings.modeBus => 'أتوبيس',
      _ => CrowdsourcingStrings.unspecifiedMode,
    };
  }

  static String emoji(String? mode) {
    return switch (mode) {
      AppStrings.modeMicrobus => '🚐',
      AppStrings.modeMinibus => '🚌',
      AppStrings.modeTomnaya => '🛺',
      AppStrings.modeTonaya => '🛺',
      AppStrings.modeBus => '🚎',
      _ => '?',
    };
  }

  static Color color(String? mode) {
    return switch (mode) {
      AppStrings.modeMicrobus => AppColors.microbusColor,
      AppStrings.modeMinibus => AppColors.minibusColor,
      AppStrings.modeTomnaya => AppColors.tonayaColor,
      AppStrings.modeTonaya => AppColors.tonayaColor,
      AppStrings.modeBus => AppColors.busColor,
      _ => AppColors.primaryTeal,
    };
  }
}
