import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

class CarlogAppTheme {
  static ThemeData light() {
    return _buildTheme(ThemeData.light(useMaterial3: true), CarlogColors.light);
  }

  static ThemeData dark() {
    return _buildTheme(ThemeData.dark(useMaterial3: true), CarlogColors.dark);
  }

  static ThemeData _buildTheme(ThemeData base, CarlogColors colors) {
    final textTheme = base.textTheme
        .apply(fontFamily: CarlogTextStyles.fontFamily)
        .copyWith(
          titleLarge: CarlogTextStyles.title.copyWith(
            color: colors.textPrimary,
          ),
          titleMedium: CarlogTextStyles.section.copyWith(
            color: colors.textPrimary,
          ),
          bodyLarge: CarlogTextStyles.primary.copyWith(
            color: colors.textPrimary,
          ),
          bodyMedium: CarlogTextStyles.primary.copyWith(
            color: colors.textPrimary,
          ),
          bodySmall: CarlogTextStyles.secondary.copyWith(
            color: colors.textSecondary,
          ),
          labelLarge: CarlogTextStyles.button.copyWith(color: Colors.white),
          labelMedium: CarlogTextStyles.metadata.copyWith(
            color: colors.textSecondary,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: colors.bg,
      cardColor: colors.bgCard,
      dividerColor: colors.border,
      colorScheme: base.colorScheme.copyWith(
        primary: colors.flame,
        secondary: colors.red,
        surface: colors.bgCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        titleSpacing: 20,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: CarlogTextStyles.section.copyWith(
          color: colors.textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colors.flame.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.bgCard,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.flame, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.flame,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: colors.border),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      extensions: [colors],
    );
  }
}
