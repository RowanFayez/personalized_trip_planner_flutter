import 'package:flutter/material.dart';

/// App color palette based on NextStation UI mockups
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryTeal = Color(0xFF00BCD4); // Light teal from logo
  static const Color primaryDarkTeal = Color(0xFF008FA1); // Darker teal
  static const Color accentRed = Color(0xFFE53935); // Location pin red

  // Background Colors - 
  static const Color backgroundDark = Color(0xFF0E1D25); // Main background
  static const Color searchInputBackground = Color(
    0xFF1E3A47,
  ); // Darker blue for search fields (matches 2nd image)
  static const Color surfaceDark = Color(0xFF2A4858); // Card/surface dark blue
  static const Color surfaceLight = Color(0xFF355566); // Lighter surface blue

  // Transport Mode Colors
  static const Color walkColor = Color(0xFFFFC107); // Yellow/amber for walking
  static const Color tramColor = Color(0xFF2196F3); // Blue for tram
  static const Color microbusColor = Color(0xFFFF9800); // Orange for microbus
  static const Color minibusColor = Color(0xFF9C27B0); // Purple for minibus
  static const Color busColor = Color(0xFF4CAF50); // Green for bus
  static const Color tonayaColor = Color(0xFFE91E63);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB0BEC5); // Light gray
  static const Color textTertiary = Color(0xFF78909C); // Muted gray
  static const Color textHint = Color(0xFF546E7A); // Hint text

  // UI Element Colors
  static const Color divider = Color(0xFF37474F);
  static const Color border = Color(0xFF455A64);
  static const Color shadow = Color(0x40000000);
  static const Color overlay = Color(0x80000000);

  // Status/Badge Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // // Route Preference Badge Colors
  // static const Color badgeFastest = Color(0xFF1DE9B6);
  // static const Color badgeCheapest = Color(0xFF66BB6A);
  // static const Color badgeSimplest = Color(0xFF5C6BC0);

  // Map UI Elements
  static const Color currentLocationButton = Color(
    0xFF1E3A47,
  ); // Darker blue button
  static const Color mapPin = Color(0xFFE53935); // Red pin
  static const Color routeLine = Color(0xFF00BCD4); // Primary route color
}
