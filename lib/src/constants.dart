library constants;

import 'package:flutter/material.dart';

abstract class Consts {
  static const double appBorderRadius = 16;
}

abstract class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: const [],
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.white12.withOpacity(0.1),
    //scaffoldBackgroundColor: const Color.fromARGB(255, 31, 30, 44),
    //backgroundColor: const Color.fromARGB(255, 31, 30, 44),
    extensions: const [],
  );
}
