import 'package:flutter/material.dart';

/// Palette extraite des maquettes Claude Design (design/Jangalekat.dc.html).
class AppColors {
  AppColors._();

  static const background = Color(0xFFFBFAF7);
  static const card = Color(0xFFF2EFE8);
  static const cardBorder = Color(0xFFE7E2D8);
  static const dashedBorder = Color(0xFFD8D2C4);

  static const textDark = Color(0xFF0E1814);
  static const textMuted = Color(0xFF6E7D74);
  static const textFaint = Color(0xFF9FAA9F);
  static const textOnDark = Color(0xFFF5F8F3);

  static const brandDark = Color(0xFF053524);
  static const brandGold = Color(0xFFF4B942);
  static const accentGreen = Color(0xFF0D9F5E);
  static const accentGreenText = Color(0xFF0A7448);
  static const accentGreenDarkText = Color(0xFF052A1C);
  static const accentGreenBg = Color(0xFFEEF8F1);
  static const accentGreenBgStrong = Color(0xFFDCF2E4);
  static const accentGreenSoft = Color(0xFF4ECF93);

  static const warningBg = Color(0xFFFBF0DA);
  static const warningText = Color(0xFF8C4A20);

  static const dangerText = Color(0xFFC1652F);
  static const dangerBg = Color(0xFFF7E1D3);
  static const bucketMid = Color(0xFFE0A339);

  static Color avgColor(double avg) {
    if (avg >= 12) return accentGreenText;
    if (avg >= 10) return warningText;
    return dangerText;
  }

  static Color avgBg(double avg) {
    if (avg >= 12) return accentGreenBgStrong;
    if (avg >= 10) return warningBg;
    return dangerBg;
  }
}
