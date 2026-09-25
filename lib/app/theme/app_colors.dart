import 'package:flutter/material.dart';

/// Servio's palette. See docs/DESIGN.md for the concept behind it.
///
/// Three hues carry meaning across the whole app, so users learn them once:
/// **ink** (navy) for placement decisions and supervision, **sky** (cyan)
/// for attendance, and **blush** (pink) for the logbook. Everything else is
/// a neutral, and the semantic colours are reserved for genuine outcomes
/// (approved, needs attention, rejected).
abstract final class AppColors {
  // Ink — the primary brand colour. Placement decisions and supervision.
  static const ink = Color(0xFF16365C);
  static const inkDeep = Color(0xFF0D2541);
  static const inkSoft = Color(0xFFE6ECF4);

  // Sky — attendance.
  static const sky = Color(0xFFBFE5EE);
  static const skyStrong = Color(0xFF1F7A91);
  static const skySoft = Color(0xFFE8F5F9);

  // Blush — the logbook.
  static const blush = Color(0xFFF6D0EA);
  static const blushStrong = Color(0xFF9E3A72);
  static const blushSoft = Color(0xFFFCEBF6);

  // Neutrals.
  static const mist = Color(0xFFF3F5F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF7F9FC);
  static const line = Color(0xFFE3E8EF);
  static const lineStrong = Color(0xFFCBD3DE);
  static const textPrimary = Color(0xFF0F2742);
  static const textSecondary = Color(0xFF5A6A7F);
  static const textTertiary = Color(0xFF8A97A8);

  // Semantic outcomes.
  static const success = Color(0xFF1B7F55);
  static const successSoft = Color(0xFFE2F3EA);
  static const warning = Color(0xFFA86A12);
  static const warningSoft = Color(0xFFFCF1DE);
  static const error = Color(0xFFC0344A);
  static const errorSoft = Color(0xFFFBE6E9);

  // Names kept from the first design system so older call sites still read
  // naturally.
  static const primary = ink;
  static const secondary = textSecondary;
  static const information = skyStrong;
  static const background = mist;
  static const divider = line;
}
