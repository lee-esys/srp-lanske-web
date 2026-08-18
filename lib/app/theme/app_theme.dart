import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData _baseTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
  useMaterial3: true,
);

final TextTheme _textTheme =
    GoogleFonts.notoSansJpTextTheme(_baseTheme.textTheme);

final TextStyle _appBarTitleTextStyle = GoogleFonts.notoSansJp(
  fontSize: 22,
  fontWeight: FontWeight.w500,
  color: _baseTheme.colorScheme.onSurface,
);

final ThemeData appTheme = _baseTheme.copyWith(
  textTheme: _textTheme,
  appBarTheme: AppBarTheme(
    titleTextStyle: _appBarTitleTextStyle,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      textStyle: GoogleFonts.notoSansJp(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      textStyle: GoogleFonts.notoSansJp(
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
);

final ThemeData doublesAppTheme = appTheme.copyWith(
  appBarTheme: appTheme.appBarTheme.copyWith(
    titleTextStyle: _appBarTitleTextStyle.copyWith(
      color: _baseTheme.colorScheme.onPrimaryContainer,
      backgroundColor:
          _baseTheme.colorScheme.primaryContainer.withValues(alpha: 0.92),
    ),
  ),
);
