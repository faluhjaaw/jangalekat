import 'package:flutter/material.dart';

/// Palette extraite des maquettes Claude Design (design/Jangalekat.dc.html),
/// avec une variante sombre. Les couleurs sont des getters (pas des
/// `const`) qui basculent selon [AppColors.dark], mis a jour par
/// `AppState.setDarkMode` — c'est le seul etat globalement mutable de l'app,
/// pragmatique ici car aucun ecran ne passe par `Theme.of(context)`.
class AppColors {
  AppColors._();

  static bool _dark = false;

  static void setDark(bool value) => _dark = value;

  static Color get background =>
      _dark ? const Color(0xFF121712) : const Color(0xFFFBFAF7);
  static Color get card =>
      _dark ? const Color(0xFF1C231D) : const Color(0xFFF2EFE8);
  static Color get cardBorder =>
      _dark ? const Color(0xFF2B342B) : const Color(0xFFE7E2D8);
  static Color get dashedBorder =>
      _dark ? const Color(0xFF3A443A) : const Color(0xFFD8D2C4);

  static Color get textDark =>
      _dark ? const Color(0xFFF5F8F3) : const Color(0xFF0E1814);
  static Color get textMuted =>
      _dark ? const Color(0xFFA7B3A9) : const Color(0xFF6E7D74);
  static Color get textFaint =>
      _dark ? const Color(0xFF748073) : const Color(0xFF9FAA9F);
  static const textOnDark = Color(0xFFF5F8F3);

  static const brandDark = Color(0xFF053524);
  static const brandGold = Color(0xFFF4B942);
  static const accentGreen = Color(0xFF0D9F5E);
  static Color get accentGreenText =>
      _dark ? const Color(0xFF4ECF93) : const Color(0xFF0A7448);
  static const accentGreenDarkText = Color(0xFF052A1C);
  static Color get accentGreenBg =>
      _dark ? const Color(0xFF16261C) : const Color(0xFFEEF8F1);
  static Color get accentGreenBgStrong =>
      _dark ? const Color(0xFF1D3A28) : const Color(0xFFDCF2E4);
  static const accentGreenSoft = Color(0xFF4ECF93);

  static Color get warningBg =>
      _dark ? const Color(0xFF3A2D14) : const Color(0xFFFBF0DA);
  static Color get warningText =>
      _dark ? const Color(0xFFE0A968) : const Color(0xFF8C4A20);

  static Color get dangerText =>
      _dark ? const Color(0xFFE08A5C) : const Color(0xFFC1652F);
  static Color get dangerBg =>
      _dark ? const Color(0xFF3A2A1E) : const Color(0xFFF7E1D3);
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
