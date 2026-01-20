import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData defaultDark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.teal,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      secondary: Colors.tealAccent,
      surface: const Color(0xFF1F1F1F),
    ),
  );

  static final ThemeData blueGradient = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      secondary: Colors.blueAccent,
      surface: const Color(0xFF161B22),
    ),
  );

  static final ThemeData purpleNeon = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.purple,
    scaffoldBackgroundColor: const Color(0xFF1A0B2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D144B),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      secondary: Colors.pinkAccent,
      surface: const Color(0xFF2D144B),
    ),
  );

  static final ThemeData greenDark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.green,
    scaffoldBackgroundColor: const Color(0xFF0A1F0A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF143014),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      secondary: Colors.lightGreenAccent,
      surface: const Color(0xFF143014),
    ),
  );

  static ThemeData getThemeFromIndex(int index) {
    switch (index) {
      case 1:
        return blueGradient;
      case 2:
        return purpleNeon;
      case 3:
        return greenDark;
      default:
        return defaultDark;
    }
  }

  static Color getBubbleColor(int themeIndex, bool isMe) {
    switch (themeIndex) {
      case 1:
        return isMe ? Colors.blue.shade700 : Colors.blueGrey.shade800;
      case 2:
        return isMe ? Colors.purple.shade700 : Colors.deepPurple.shade900;
      case 3:
        return isMe ? Colors.green.shade700 : Colors.teal.shade900;
      default:
        return isMe ? Colors.teal.shade700 : Colors.grey.shade800;
    }
  }

  static List<Color> getGradient(int themeIndex) {
    switch (themeIndex) {
      case 1:
        return [Colors.blue.shade900, Colors.blue.shade700];
      case 2:
        return [Colors.purple.shade900, Colors.pink.shade700];
      case 3:
        return [Colors.green.shade900, Colors.lightGreen.shade700];
      default:
        return [const Color(0xFF121212), const Color(0xFF1F1F1F)];
    }
  }
}
