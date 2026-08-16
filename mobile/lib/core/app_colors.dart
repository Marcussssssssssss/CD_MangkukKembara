import 'package:flutter/material.dart';

/// Central green, sage, white, and gold palette for MangkukKembara.
abstract final class AppColors {
  // ── Primary palette ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF335C31); // Forest green
  static const Color primaryDark = Color(0xFF283427); // Charcoal green
  static const Color primaryLight = Color(0xFF61885B); // Sage green
  static const Color primaryContainer = Color(0xFFACBBAB); // Pale sage

  // ── Accent / secondary palette ───────────────────────────────────────────────
  static const Color accent = Color(0xFFF9B10E); // Golden yellow
  static const Color accentLight = Color(0xFFF3CC4E); // Light gold
  static const Color accentDark = Color(0xFFB57900); // Deep gold
  static const Color accentContainer = Color(0xFFFEF5E4); // Cream yellow

  // ── Surface / background ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFFDFDFD); // White card
  static const Color surfaceVariant = Color(0xFFF5F7F3); // Soft background
  static const Color divider = Color(0xFFCCD6C8); // Pale green-grey

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF283427); // Charcoal
  static const Color textSecondary = Color(0xFF497649); // Natural green
  static const Color textHint = Color(0xFF929992); // Grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color textOnAccent = Color(0xFF283427); // Dark text on gold

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF497649);
  static const Color successLight = Color(0xFFEEF3EC);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ── Tag / chip backgrounds ────────────────────────────────────────────────────
  static const Color tagBg = Color(0xFFEEF3EC);
  static const Color tagText = Color(0xFF335C31);

  // ── Map placeholder ──────────────────────────────────────────────────────────
  static const Color mapBg = Color(0xFF88A47D); // Light land green
  static const Color mapRoad = Color(0xFFFFFFFF);
  static const Color mapWater = Color(0xFF93B3EA);
  static const Color mapGrid = Color(0xFFACBBAB);

  // ── Bottom navigation ─────────────────────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navSelected = Color(0xFFF9B10E);
  static const Color navUnselected = Color(0xFF61885B);

  // ── Collected / uncollected tiffin ────────────────────────────────────────────
  static const Color collected = Color(0xFF4CAF50);
  static const Color uncollected = Color(0xFF9E9E9E);

  // ── Rating star ───────────────────────────────────────────────────────────────
  static const Color starFilled = Color(0xFFF9B10E);
  static const Color starEmpty = Color(0xFFE0E0E0);
}
