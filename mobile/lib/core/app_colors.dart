import 'package:flutter/material.dart';

/// Central color palette for MangkukKembara.
/// Inspired by Malaysian heritage — warm terracotta, heritage gold, and cream.
abstract final class AppColors {
  // ── Primary palette ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF8B4513); // Saddle brown
  static const Color primaryDark = Color(0xFF5C2D0A); // Deep brown
  static const Color primaryLight = Color(0xFFB5622A); // Warm terracotta
  static const Color primaryContainer = Color(0xFFF0D8C0); // Light terracotta

  // ── Accent / secondary palette ───────────────────────────────────────────────
  static const Color accent = Color(0xFFD4A017); // Heritage gold
  static const Color accentLight = Color(0xFFE8C050); // Bright gold
  static const Color accentDark = Color(0xFF9E7510); // Deep gold
  static const Color accentContainer = Color(0xFFFBF0CC); // Pale gold

  // ── Surface / background ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFFDF6E3); // Warm cream
  static const Color surface = Color(0xFFFFFFFF); // Pure white card
  static const Color surfaceVariant = Color(
    0xFFF5EFE0,
  ); // Slightly tinted cream
  static const Color divider = Color(0xFFE8D9C0); // Warm divider

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3E2C1A); // Deep brown text
  static const Color textSecondary = Color(0xFF6B4C2A); // Medium brown text
  static const Color textHint = Color(0xFF9E7B4A); // Muted brown hint
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color textOnAccent = Color(0xFF3E2C1A); // Dark text on gold

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ── Tag / chip backgrounds ────────────────────────────────────────────────────
  static const Color tagBg = Color(0xFFF0E6D0);
  static const Color tagText = Color(0xFF8B4513);

  // ── Map placeholder ──────────────────────────────────────────────────────────
  static const Color mapBg = Color(0xFFE8F0D0); // Soft sage green
  static const Color mapRoad = Color(0xFFFFFFFF);
  static const Color mapWater = Color(0xFFB3D9F0);
  static const Color mapGrid = Color(0xFFD4E6B8);

  // ── Bottom navigation ─────────────────────────────────────────────────────────
  static const Color navBackground = Color(0xFF5C2D0A);
  static const Color navSelected = Color(0xFFD4A017);
  static const Color navUnselected = Color(0xFF9E7B6A);

  // ── Collected / uncollected tiffin ────────────────────────────────────────────
  static const Color collected = Color(0xFF4CAF50);
  static const Color uncollected = Color(0xFF9E9E9E);

  // ── Rating star ───────────────────────────────────────────────────────────────
  static const Color starFilled = Color(0xFFD4A017);
  static const Color starEmpty = Color(0xFFE0E0E0);
}
