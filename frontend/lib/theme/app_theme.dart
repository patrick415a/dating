import 'package:flutter/material.dart';

class AppBrand {
  static const name = '만약에 우리';
  static const tagline = '당신의 특별한 인연을 찾아드립니다';
}

/// Shared palette for the ivory and dried-rose design.
/// Screen-local color names stay in place to keep existing widget logic intact.
class AppColors {
  static const background = Color(0xFFFAF7F2);
  static const canvas = Color(0xFFEEE8E2);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFA95869);
  static const primaryEnd = Color(0xFF9C4E60);
  static const primarySoft = Color(0xFFF5E7E8);
  static const blush = Color(0xFFE5B9BF);
  static const text = Color(0xFF352C30);
  static const textSecondary = Color(0xFF786D72);
  static const muted = Color(0xFFA99B9F);
  static const border = Color(0xFFE6DDD8);
  static const borderStrong = Color(0xFFCDBFC1);
  static const shadow = Color(0x14352C30);
  static const onPrimary = Color(0xFFFFFFFF);
  static const gold = Color(0xFF916826);
  static const goldSoft = Color(0xFFF7F0E3);
  static const sage = Color(0xFF60775E);
  static const sageSoft = Color(0xFFEDF2EA);
  static const blue = Color(0xFF547383);
  static const blueSoft = Color(0xFFEAF0F4);
  static const peachSoft = Color(0xFFF5E9DE);
  static const error = Color(0xFFB44751);
  static const kakao = Color(0xFFFFE98A);
}

class AppTheme {
  static const fontFamily = 'Pretendard';
  static const fontFallback = <String>[
    'Apple SD Gothic Neo',
    'Malgun Gothic',
    'Noto Sans KR',
    'Segoe UI Emoji',
  ];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primaryEnd,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      error: AppColors.error,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      dividerColor: AppColors.border,
      shadowColor: AppColors.shadow,
      disabledColor: AppColors.muted,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: TextStyle(color: AppColors.onPrimary, fontFamily: fontFamily),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.blush.withValues(alpha: 0.5),
        selectionHandleColor: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.muted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
