import 'package:flutter/material.dart';

/// Dashboard-specific color themes
class DashboardThemes {
  // Private constructor to prevent instantiation
  DashboardThemes._();

  /// Citizen Dashboard - Ocean Blue Theme
  /// Colors inspired by water, trust, and accessibility
  static const CitizenTheme = DashboardTheme(
    primaryColor: Color(0xFF1976D2), // Deep Ocean Blue
    primaryVariant: Color(0xFF1565C0), // Darker Blue
    secondaryColor: Color(0xFF03DAC6), // Aqua/Cyan
    secondaryVariant: Color(0xFF018786), // Darker Aqua
    surfaceColor: Color(0xFFF8F9FA), // Light Gray-Blue
    backgroundColor: Color(0xFFE3F2FD), // Very Light Blue
    errorColor: Color(0xFFD32F2F), // Red
    onPrimaryColor: Colors.white,
    onSecondaryColor: Colors.black,
    onSurfaceColor: Color(0xFF1A1A1A), // Dark Gray
    onBackgroundColor: Color(0xFF1A1A1A), // Dark Gray
    cardColor: Colors.white,
    dividerColor: Color(0xFFE0E0E0), // Light Gray
    shadowColor: Color(0x1A1976D2), // Blue Shadow
    accentColor: Color(0xFF2196F3), // Light Blue
    successColor: Color(0xFF4CAF50), // Green
    warningColor: Color(0xFFFF9800), // Orange
    dangerColor: Color(0xFFF44336), // Red
    infoColor: Color(0xFF00BCD4), // Cyan
  );

  /// Researcher Dashboard - Scientific Green Theme
  /// Colors inspired by nature, analysis, and scientific research
  static const ResearcherTheme = DashboardTheme(
    primaryColor: Color(0xFF2E7D32), // Forest Green
    primaryVariant: Color(0xFF1B5E20), // Darker Green
    secondaryColor: Color(0xFF81C784), // Light Green
    secondaryVariant: Color(0xFF4CAF50), // Medium Green
    surfaceColor: Color(0xFFF1F8E9), // Light Green-Gray
    backgroundColor: Color(0xFFE8F5E8), // Very Light Green
    errorColor: Color(0xFFD32F2F), // Red
    onPrimaryColor: Colors.white,
    onSecondaryColor: Colors.black,
    onSurfaceColor: Color(0xFF1A1A1A), // Dark Gray
    onBackgroundColor: Color(0xFF1A1A1A), // Dark Gray
    cardColor: Colors.white,
    dividerColor: Color(0xFFE0E0E0), // Light Gray
    shadowColor: Color(0x1A2E7D32), // Green Shadow
    accentColor: Color(0xFF66BB6A), // Medium Green
    successColor: Color(0xFF4CAF50), // Green
    warningColor: Color(0xFFFF9800), // Orange
    dangerColor: Color(0xFFF44336), // Red
    infoColor: Color(0xFF26A69A), // Teal
  );

  /// Policy Maker Dashboard - Authority Purple Theme
  /// Colors inspired by authority, sophistication, and policy-making
  static const PolicyMakerTheme = DashboardTheme(
    primaryColor: Color(0xFF673AB7), // Deep Purple
    primaryVariant: Color(0xFF512DA8), // Darker Purple
    secondaryColor: Color(0xFFBA68C8), // Light Purple
    secondaryVariant: Color(0xFF9C27B0), // Medium Purple
    surfaceColor: Color(0xFFF3E5F5), // Light Purple-Gray
    backgroundColor: Color(0xFFEDE7F6), // Very Light Purple
    errorColor: Color(0xFFD32F2F), // Red
    onPrimaryColor: Colors.white,
    onSecondaryColor: Colors.black,
    onSurfaceColor: Color(0xFF1A1A1A), // Dark Gray
    onBackgroundColor: Color(0xFF1A1A1A), // Dark Gray
    cardColor: Colors.white,
    dividerColor: Color(0xFFE0E0E0), // Light Gray
    shadowColor: Color(0x1A673AB7), // Purple Shadow
    accentColor: Color(0xFF9C27B0), // Medium Purple
    successColor: Color(0xFF4CAF50), // Green
    warningColor: Color(0xFFFF9800), // Orange
    dangerColor: Color(0xFFF44336), // Red
    infoColor: Color(0xFF3F51B5), // Indigo
  );
}

/// Dashboard theme data class
class DashboardTheme {
  final Color primaryColor;
  final Color primaryVariant;
  final Color secondaryColor;
  final Color secondaryVariant;
  final Color surfaceColor;
  final Color backgroundColor;
  final Color errorColor;
  final Color onPrimaryColor;
  final Color onSecondaryColor;
  final Color onSurfaceColor;
  final Color onBackgroundColor;
  final Color cardColor;
  final Color dividerColor;
  final Color shadowColor;
  final Color accentColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;
  final Color infoColor;

  const DashboardTheme({
    required this.primaryColor,
    required this.primaryVariant,
    required this.secondaryColor,
    required this.secondaryVariant,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.errorColor,
    required this.onPrimaryColor,
    required this.onSecondaryColor,
    required this.onSurfaceColor,
    required this.onBackgroundColor,
    required this.cardColor,
    required this.dividerColor,
    required this.shadowColor,
    required this.accentColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
    required this.infoColor,
  });

  /// Convert to Flutter ThemeData with brightness support
  ThemeData toThemeData({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      brightness: brightness,
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      primaryColorDark: primaryVariant,
      primaryColorLight: secondaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: isDark ? const Color(0xFF1E1E1E) : surfaceColor,
        background: isDark ? const Color(0xFF121212) : backgroundColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onSurface: isDark ? Colors.white70 : onSurfaceColor,
        onBackground: isDark ? Colors.white70 : onBackgroundColor,
        brightness: brightness,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF2D2D2D) : cardColor,
        shadowColor: isDark ? Colors.black54 : shadowColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey[600]! : dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey[600]! : dividerColor),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey[600]! : dividerColor,
        thickness: 1,
      ),
    );
  }

  /// Create MaterialColor from Color
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

/// Theme extensions for custom colors
extension DashboardThemeExtension on ThemeData {
  DashboardTheme get dashboardTheme {
    if (primaryColor == DashboardThemes.CitizenTheme.primaryColor) {
      return DashboardThemes.CitizenTheme;
    } else if (primaryColor == DashboardThemes.ResearcherTheme.primaryColor) {
      return DashboardThemes.ResearcherTheme;
    } else if (primaryColor == DashboardThemes.PolicyMakerTheme.primaryColor) {
      return DashboardThemes.PolicyMakerTheme;
    }
    return DashboardThemes.CitizenTheme; // Default fallback
  }
}
