import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/custom_places_service.dart';
import '../../../map_picker/presentation/view/map_picker_page.dart';

/// Opens the Add / Edit custom place bottom sheet.
/// Returns [void]; changes are committed directly via [CustomPlacesService].
Future<void> showCustomPlaceSheet(
  BuildContext context, {
  required CustomPlacesService service,
  CustomPlace? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CustomPlaceSheet(
      service: service,
      existing: existing,
    ),
  );
}

class _CustomPlaceSheet extends StatefulWidget {
  final CustomPlacesService service;
  final CustomPlace? existing;

  const _CustomPlaceSheet({required this.service, this.existing});

  @override
  State<_CustomPlaceSheet> createState() => _CustomPlaceSheetState();
}

class _CustomPlaceSheetState extends State<_CustomPlaceSheet> {
  late final TextEditingController _labelController;
  double? _lat;
  double? _lng;
  String? _locationName;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  bool get _canSave =>
      _labelController.text.trim().isNotEmpty &&
      _lat != null &&
      _lng != null &&
      !_isSaving;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    if (existing != null) {
      _lat = existing.latitude;
      _lng = existing.longitude;
      _locationName = 'Saved location';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await context.push<MapPickerResult>('/map-picker/custom');
    if (result != null && mounted) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _locationName = result.placeName;
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    try {
      final label = _labelController.text.trim();
      if (_isEdit) {
        final updated = CustomPlace(
          id: widget.existing!.id,
          label: label,
          latitude: _lat!,
          longitude: _lng!,
        );
        await widget.service.updateCustomPlace(updated);
      } else {
        final place = CustomPlace(
          id: CustomPlacesService.newId(),
          label: label,
          latitude: _lat!,
          longitude: _lng!,
        );
        await widget.service.addCustomPlace(place);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    setState(() => _isSaving = true);
    try {
      await widget.service.deleteCustomPlace(existing.id);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            _isEdit ? 'Edit place' : 'Add custom place',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),

          // Label field
          TextField(
            controller: _labelController,
            maxLength: 40,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textDirection: TextDirection.rtl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Place name (e.g. Gym, Mom\'s house)',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13.sp,
              ),
              counterStyle: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11.sp,
              ),
              filled: true,
              fillColor: AppColors.searchInputBackground,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.surfaceLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.surfaceLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primaryTeal),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Pick on map button
          OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: Icon(Icons.map_outlined, size: 18.r),
            label: Text(
              _lat == null ? 'Pick location on map' : 'Change location',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: BorderSide(color: AppColors.primaryTeal),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),

          // Location preview
          if (_locationName != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryTeal,
                  size: 16.r,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _locationName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 20.h),

          // Save button
          SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed: _canSave ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.surfaceLight,
                disabledForegroundColor: AppColors.textTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Save place'),
            ),
          ),

          // Delete button (edit mode only)
          if (_isEdit) ...[
            SizedBox(height: 10.h),
            SizedBox(
              height: 44.h,
              child: TextButton(
                onPressed: _isSaving ? null : _delete,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentRed,
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Delete place'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
