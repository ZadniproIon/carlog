import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CarlogTextStyles {
  static const String fontFamily = 'DMSans';

  static TextStyle title = _dmSans(fontSize: 22, fontWeight: FontWeight.w600);
  static TextStyle section = _dmSans(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle primary = _dmSans(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle secondary = _dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static TextStyle metadata = _dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static TextStyle button = _dmSans(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle _dmSans({
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamilyFallback: _emojiFallbackFamilies,
    );
  }

  static List<String> get _emojiFallbackFamilies {
    if (kIsWeb) {
      return const [
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
        'sans-serif',
      ];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const ['SamsungColorEmoji', 'Noto Color Emoji', 'sans-serif'];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const ['Apple Color Emoji'];
      case TargetPlatform.windows:
        return const ['Segoe UI Emoji'];
      case TargetPlatform.linux:
        return const ['Noto Color Emoji', 'sans-serif'];
      case TargetPlatform.fuchsia:
        return const ['Noto Color Emoji'];
    }
  }
}

