import 'package:flutter/material.dart';

/// Design tokens inspired by Leonxlnx/taste-skill:
/// Restrained Obsidian, Slate, and Electric Crimson/Neon accents.
/// Banning generic AI gradients and default muddy shadows.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF090C10);
  static const Color surface = Color(0xFF131822);
  static const Color surfaceElevated = Color(0xFF1C2333);
  static const Color surfaceOverlay = Color(0xCC0D111A);
  
  // Borders & Dividers
  static const Color border = Color(0xFF263044);
  static const Color borderLight = Color(0x1AFFFFFF);
  static const Color borderFocus = Color(0xFF6366F1);
  
  // Accents
  static const Color primary = Color(0xFFFF3366); // Electric Coral/Crimson
  static const Color primaryLight = Color(0xFFFF6B8B);
  static const Color secondary = Color(0xFF6366F1); // Indigo / Cyber Neon
  static const Color secondaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF06B6D4); // Cyan pop
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFF090C10);
  
  // Story Gradient Ring (High-taste conic gradient)
  static const List<Color> storyGradient = [
    Color(0xFFFF3366),
    Color(0xFFFF8A00),
    Color(0xFFE040FB),
    Color(0xFF6366F1),
  ];

  // Glass highlight
  static const Color glassHighlight = Color(0x14FFFFFF);
}
