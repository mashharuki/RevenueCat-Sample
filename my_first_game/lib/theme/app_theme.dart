import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const cyan = Color(0xFF00E5FF);
  static const pink = Color(0xFFFF2EA6);
  static const orange = Color(0xFFFFB84D);
  static const purple = Color(0xFFB026FF);
  static const background = Color(0xFF05060F);
  static const danger = Color(0xFFFF3B5C);

  static TextStyle orbitron({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = Colors.white,
    double letterSpacing = 2,
  }) {
    return GoogleFonts.orbitron(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle rajdhani({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double letterSpacing = 1,
  }) {
    return GoogleFonts.rajdhani(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
