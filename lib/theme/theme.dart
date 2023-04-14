import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primColor = Colors.cyan;
  static const Color _secColor = Color.fromRGBO(220, 118, 81, 1);
  static const Color _terColor = Colors.blueGrey;

  static const TextTheme _defTextTheme = TextTheme(
      titleSmall: TextStyle(fontSize: 16.0),
      titleMedium: TextStyle(fontSize: 18.0),
      titleLarge: TextStyle(fontSize: 24.0),
      bodySmall: TextStyle(fontSize: 14.0),
      bodyMedium: TextStyle(fontSize: 18.0),
      bodyLarge: TextStyle(fontSize: 20.0));

  static ThemeData light = ThemeData.light().copyWith(
    textTheme: _defTextTheme,
    colorScheme: const ColorScheme.light(
      primary: _primColor,
      secondary: _secColor,
      tertiary: _terColor,
    ),
  );

  static ThemeData dark = ThemeData.dark(useMaterial3: true).copyWith(
    textTheme: _defTextTheme,
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        actionsIconTheme: const IconThemeData(color: _primColor)),
    cardTheme: CardTheme(color: Colors.grey[850]),
    dividerTheme: const DividerThemeData(color: _terColor),
    colorScheme: const ColorScheme.dark(
      primary: _primColor,
      secondary: _secColor,
      tertiary: _terColor,
    ),
  );
}
