import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 'DM Sans' pour tout le texte de l'app (une seule police, meme style que
/// l'ecran Fiches de cours). 'Sometype Mono' a ete retire pour homogeneiser
/// l'ensemble des ecrans.
class AppText {
  AppText._();

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textDark,
    letterSpacing: letterSpacing,
    height: height,
  );
}
