library constants;

import 'package:flutter/material.dart';

abstract class Consts {
  static const double appBorderRadius = 16;
}

abstract class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    extensions: const [
      PUCAppBarThemeData(
        backgroundColor: Colors.white,
      ),
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color.fromARGB(255, 22, 22, 28),
    backgroundColor: const Color.fromARGB(255, 22, 22, 28),
    extensions: const [
      PUCAppBarThemeData(
        backgroundColor: Color.fromARGB(255, 22, 22, 28),
      ),
    ],
  );
}

class PUCAppBarThemeData extends ThemeExtension<PUCAppBarThemeData> {
  final Color backgroundColor;
  final Color? foregroundColor;

  const PUCAppBarThemeData({
    required this.backgroundColor,
    this.foregroundColor,
  });

  @override
  ThemeExtension<PUCAppBarThemeData> lerp(
    ThemeExtension<PUCAppBarThemeData>? other,
    double t,
  ) {
    if (other is! PUCAppBarThemeData) {
      return this;
    }
    return PUCAppBarThemeData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      foregroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
    );
  }

  @override
  PUCAppBarThemeData copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return PUCAppBarThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
    );
  }
}
