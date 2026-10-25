import 'package:flutter/material.dart';

class AppConfig {
  const AppConfig._();

  /// Base URL of the Kumi API.
  /// Override with:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Google OAuth client ID used as `serverClientId` so the ID token audience
  /// matches the backend configuration.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration splashMinimumDuration = Duration(milliseconds: 1200);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double screenPadding = 20;
}

class AppRadius {
  const AppRadius._();

  static const double card = 16;
  static const double button = 14;
  static const double pill = 999;
}

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFFE07A3F);
  static const Color primaryDark = Color(0xFFB85E2A);
  static const Color secondary = Color(0xFF2F4858);
  static const Color surface = Color(0xFFFFF8F2);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF5FA88A);
  static const Color warning = Color(0xFFD9A441);
  static const Color danger = Color(0xFFC7524A);
  static const Color muted = Color(0xFF8A8F94);
  static const Color fox = Color(0xFFE07A3F);
  static const Color foxDark = Color(0xFFB85E2A);
  static const Color foxCream = Color(0xFFFFF3E6);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.surface,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.secondary,
      displayColor: AppColors.secondary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceAlt,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.08)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceAlt,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
