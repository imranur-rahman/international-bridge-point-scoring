import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../storage/storage.dart';

/// The green of a card table.
const Color feltGreen = Color(0xFF1E6B45);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: feltGreen,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}

ThemeMode themeModeOf(ThemeModeSetting setting) => switch (setting) {
  ThemeModeSetting.system => ThemeMode.system,
  ThemeModeSetting.light => ThemeMode.light,
  ThemeModeSetting.dark => ThemeMode.dark,
};

/// The relative luminance of [c] (WCAG 2).
double relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// The WCAG contrast ratio of two colors, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a), lb = relativeLuminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The color of a strain symbol, or null for the normal text color.
Color? strainColor(Strain strain, Brightness brightness, SuitColorsSetting s) {
  final light = brightness == Brightness.light;
  return switch (strain) {
    Strain.hearts => light ? const Color(0xFFB71C1C) : const Color(0xFFFF8A80),
    Strain.diamonds =>
      s == SuitColorsSetting.four
          ? (light ? const Color(0xFFA14A00) : const Color(0xFFFFB74D))
          : (light ? const Color(0xFFB71C1C) : const Color(0xFFFF8A80)),
    Strain.clubs =>
      s == SuitColorsSetting.four
          ? (light ? const Color(0xFF1B5E20) : const Color(0xFF81C784))
          : null,
    Strain.spades || Strain.noTrump => null,
  };
}
