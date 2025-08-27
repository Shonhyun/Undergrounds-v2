import 'package:flutter/material.dart';
import './elevation_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData();
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: ElevationColors.dark01dp,
      foregroundColor: Colors.red,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white, // Explicitly set title text color
        fontSize: 20,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey[400]),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white, // Selected tab color
      unselectedLabelColor: Colors.grey, // Unselected tab color
      indicator: BoxDecoration(
        color: Colors.white, // Tab indicator color
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red), // Default border
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
        ), // Subtle red when not focused
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white), // Strong red when focused
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ElevationColors.dark01dp,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    ),
    cardTheme: CardThemeData(color: ElevationColors.dark02dp),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Colors.red, 
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ElevationColors.dark01dp,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      )
    )
  );
}
