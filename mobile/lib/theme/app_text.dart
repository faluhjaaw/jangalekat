import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 'DM Sans' pour le texte courant, 'Sometype Mono' pour les valeurs
/// chiffrees (moyennes, telephones, PIN) comme dans la maquette.
class AppText {
  AppText._();

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textDark,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textDark,
    double? letterSpacing,
  }) => GoogleFonts.sometypeMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
