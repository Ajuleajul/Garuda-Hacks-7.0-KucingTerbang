import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class CuramindColors {
  static const sage = Color(0xFF5A7D6E);
  static const sageDeep = Color(0xFF3D5A4E);
  static const sageSoft = Color(0xFFD5E5DC);

  static const slate = Color(0xFF6B8499);
  static const ocean = Color(0xFF4A6678);
  static const mistBlue = Color(0xFFD9E4EC);

  static const mist = Color(0xFFE6EEF0);
  static const surface = Color(0xFFF4F8F9);
  static const white = Color(0xFFFFFFFF);

  static const ink = Color(0xFF1A2830);
  static const inkMuted = Color(0xFF5A6B72);

  static const danger = Color(0xFF8F7A7A);
}

ThemeData buildCuramindTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: CuramindColors.sage,
      onPrimary: CuramindColors.white,
      primaryContainer: CuramindColors.sageSoft,
      onPrimaryContainer: CuramindColors.sageDeep,
      secondary: CuramindColors.slate,
      onSecondary: CuramindColors.white,
      secondaryContainer: CuramindColors.mistBlue,
      onSecondaryContainer: CuramindColors.ocean,
      surface: CuramindColors.surface,
      onSurface: CuramindColors.ink,
      onSurfaceVariant: CuramindColors.inkMuted,
      outline: CuramindColors.sageSoft,
      outlineVariant: CuramindColors.mistBlue,
      error: CuramindColors.danger,
      onError: CuramindColors.white,
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
      fillColor: CuramindColors.white.withValues(alpha: 0.78),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.outfit(
        color: CuramindColors.inkMuted,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: GoogleFonts.outfit(
        color: CuramindColors.inkMuted,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: GoogleFonts.outfit(
        color: CuramindColors.danger,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.mistBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.mistBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.slate, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CuramindColors.danger, width: 1.4),
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
      ).copyWith(
        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.none),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CuramindColors.ocean,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ).copyWith(
        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.none),
      ),
    ),
  );
}
