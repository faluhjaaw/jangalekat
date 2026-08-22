import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accentGreenText,
      primary: AppColors.accentGreenText,
      secondary: AppColors.brandGold,
      surface: AppColors.background,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
    ),
    // Feedback tactile sur tous les boutons/InkWell de l'app (auparavant
    // desactive via NoSplash, aucun retour visuel au clic). Teinte l'effet
    // avec la couleur d'accent de la marque plutot que le bleu Android par
    // defaut.
    splashColor: AppColors.accentGreenText.withValues(alpha: 0.12),
    highlightColor: AppColors.accentGreenText.withValues(alpha: 0.06),
  );
}
