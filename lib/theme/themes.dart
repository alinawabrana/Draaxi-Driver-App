import 'package:flutter/material.dart';

import '../utils/constant/colors.dart';
import 'custom_themes/bottom_navigation_bar_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/outline_button_theme.dart';
import 'custom_themes/text_button_theme.dart';
import 'custom_themes/text_field_theme.dart';
import 'custom_themes/text_theme.dart';

class ATheme {
  static ThemeData lightModeThemes = ThemeData(
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AColor.scaffoldBackgroundLight,
    cardColor: AColor.cardBackgroundLight,
    textTheme: ATextTheme.lightTextTheme,
    inputDecorationTheme: ATextFieldTheme.lightTextFormTheme,
    elevatedButtonTheme: AElevatedButtonTheme.lightButtonTheme,
    outlinedButtonTheme: AOutlinedButtonTheme.lightButtonTheme,
    textButtonTheme: ATextButtonTheme.lightButtonTheme,
    bottomNavigationBarTheme:
        ABottomNavigationBarTheme.lightBottomNavigationBarTheme,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFEC400),
      brightness: Brightness.light,
      surface: AColor.cardBackgroundLight,
    ),
  );

  static ThemeData darkModeThemes = ThemeData(
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AColor.scaffoldBackgroundDark,
    cardColor: AColor.cardBackgroundDark,
    textTheme: ATextTheme.darkTextTheme,
    inputDecorationTheme: ATextFieldTheme.darkTextFormTheme,
    elevatedButtonTheme: AElevatedButtonTheme.darkButtonTheme,
    outlinedButtonTheme: AOutlinedButtonTheme.darkButtonTheme,
    textButtonTheme: ATextButtonTheme.darkButtonTheme,
    bottomNavigationBarTheme:
        ABottomNavigationBarTheme.darkBottomNavigationBarTheme,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFEC400),
      brightness: Brightness.dark,
      surface: AColor.cardBackgroundDark,
    ),
  );
}
