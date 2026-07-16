import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class CuramindColors {
  static const sage = Color(0xFF5B7C6A);
  static const sageDeep = Color(0xFF3F5A4C);
  static const sageSoft = Color(0xFFD8E6DE);
  static const mist = Color(0xFFE8F0EB);
  static const ink = Color(0xFF1C2B24);
  static const inkMuted = Color(0xFF5A6B62);
  static const coral = Color(0xFFD4735E);
  static const coralSoft = Color(0xFFF3DED8);
  static const surface = Color(0xFFF7FAF8);
  static const white = Color(0xFFFFFFFF);
  static const danger = Color(0xFFB54A3C);
}

ThemeData buildCuramindTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: CuramindColors.sage,
      onPrimary: CuramindColors.white,
      secondary: CuramindColors.coral,
      onSecondary: CuramindColors.white,
      surface: CuramindColors.surface,
      onSurface: CuramindColors.ink,
      error: CuramindColors.danger,
    ),
    scaffoldBackgroundColor: CuramindColors.mist,
  );

  return base.copyWith(
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: CuramindColors.ink,
      displayColor: CuramindColors.ink,
    ),
    primaryTextTheme: GoogleFonts.outfitTextTheme(base.primaryTextTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: CuramindColors.ink,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: CuramindColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CuramindColors.white.withValues(alpha: 0.72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.outfit(
        color: CuramindColors.inkMuted,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: GoogleFonts.outfit(
        color: CuramindColors.inkMuted,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: CuramindColors.sageSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: CuramindColors.sageSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.sage, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.danger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CuramindColors.sageDeep,
        foregroundColor: CuramindColors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CuramindColors.sageDeep,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
