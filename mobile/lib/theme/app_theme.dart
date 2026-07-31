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
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
    ),
    splashFactory: NoSplash.splashFactory,
  );
}
