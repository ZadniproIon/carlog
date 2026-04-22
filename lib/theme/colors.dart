import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color red = Color(0xFFE11D48);
  static const Color flame = Color(0xFFF97316);
}

@immutable
class CarlogColors extends ThemeExtension<CarlogColors> {
  const CarlogColors({
    required this.bg,
    required this.bgCard,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.red,
    required this.flame,
  });

  final Color bg;
  final Color bgCard;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color red;
  final Color flame;

  static const CarlogColors light = CarlogColors(
    bg: AppColors.bg,
    bgCard: AppColors.bgCard,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    red: AppColors.red,
    flame: AppColors.flame,
  );

  static const CarlogColors dark = CarlogColors(
    bg: Color(0xFF0F1115),
    bgCard: Color(0xFF161A22),
    border: Color(0xFF202532),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFF98A2B3),
    red: AppColors.red,
    flame: AppColors.flame,
  );

  @override
  CarlogColors copyWith({
    Color? bg,
    Color? bgCard,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? red,
    Color? flame,
  }) {
    return CarlogColors(
      bg: bg ?? this.bg,
      bgCard: bgCard ?? this.bgCard,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      red: red ?? this.red,
      flame: flame ?? this.flame,
    );
  }

  @override
  CarlogColors lerp(ThemeExtension<CarlogColors>? other, double t) {
    if (other is! CarlogColors) {
      return this;
    }
    return CarlogColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      red: Color.lerp(red, other.red, t)!,
      flame: Color.lerp(flame, other.flame, t)!,
    );
  }
}

extension CarlogColorsX on BuildContext {
  CarlogColors get carlogColors => Theme.of(this).extension<CarlogColors>()!;
}

