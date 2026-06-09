import 'package:flutter/material.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import 'mode_selector_sheet.dart';

class StartModeSheet {
  const StartModeSheet._();

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String?>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const PopScope(
        canPop: false,
        child: ModeSelectorSheet(title: CrowdsourcingStrings.selectCurrentMode),
      ),
    );
  }
}
