import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta pedida
  // Fondo papel/beige claro
  static const Color _paper = Color(0xFFFDF6EC);
  // Azul marino para títulos y primario
  static const Color _navy = Color(0xFF1E3A8A);
  // Marrón cálido para acentos
  static const Color _brown = Color(0xFF8B5E3C);
  // Naranja suave para CTA
  static const Color _orange = Color(0xFFF97316);

  static ThemeData light() {
    // Creamos un ColorScheme manual para controlar mejor los tonos
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _navy,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF2A4CB3),
      onPrimaryContainer: Colors.white,
      secondary: _brown,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFC89F7D),
      onSecondaryContainer: const Color(0xFF3E2A1C),
      tertiary: _orange,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFD5B6),
      onTertiaryContainer: const Color(0xFF5B2E0C),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: _paper,
      onSurface: const Color(0xFF1C1B1A),
      surfaceContainerHighest: const Color(0xFFFFFBF6), // un poco más claro
      surfaceContainerHigh: const Color(0xFFFEF9F2),
      surfaceContainer: const Color(0xFFF9F1E6),
      surfaceContainerLow: const Color(0xFFF4EADA),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceBright: const Color(0xFFFFFFFF),
      surfaceDim: const Color(0xFFF0E7D8),
      onSurfaceVariant: const Color(0xFF54504B),
      outline: const Color(0xFF857970),
      outlineVariant: const Color(0xFFD6C9BD),
      shadow: Colors.black12,
      scrim: Colors.black54,
      inverseSurface: const Color(0xFF2E2A26),
      onInverseSurface: const Color(0xFFF6F0E6),
      inversePrimary: const Color(0xFF9DB4FF),
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: scheme.surface,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        iconColor: scheme.onSurfaceVariant,
        tileColor: scheme.surface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: scheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      // Tipografías: Merriweather (títulos) + Roboto (texto)
      textTheme: _textThemeLight(base.textTheme),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
      ),
      tabBarTheme: TabBarTheme(
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.outlineVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? scheme.primary.withOpacity(0.5)
                  : scheme.outlineVariant,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(scheme.primary),
      ),
    );
  }

  static ThemeData dark() {
    // Derivamos una versión dark de la paleta
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9DB4FF),
      onPrimary: Color(0xFF0E1E56),
      primaryContainer: Color(0xFF2A4CB3),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFD9BCA2),
      onSecondary: Color(0xFF3E2A1C),
      secondaryContainer: Color(0xFF6E4A2F),
      onSecondaryContainer: Color(0xFFFFEDE2),
      tertiary: Color(0xFFFFB784),
      onTertiary: Color(0xFF3A1E08),
      tertiaryContainer: Color(0xFF7A4625),
      onTertiaryContainer: Color(0xFFFFE7D6),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF171412),
      onSurface: Color(0xFFE9E3D9),
      surfaceContainerHighest: Color(0xFF1E1B19),
      surfaceContainerHigh: Color(0xFF1B1917),
      surfaceContainer: Color(0xFF191715),
      surfaceContainerLow: Color(0xFF171514),
      surfaceContainerLowest: Color(0xFF0F0D0C),
      surfaceBright: Color(0xFF23201D),
      surfaceDim: Color(0xFF141210),
      onSurfaceVariant: Color(0xFFCAC1B6),
      outline: Color(0xFF9C8F83),
      outlineVariant: Color(0xFF4C453D),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFEAE3D9),
      onInverseSurface: Color(0xFF2C2824),
      inversePrimary: Color(0xFF1E3A8A),
    );
    return light().copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.8,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.secondary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      cardTheme: light().cardTheme.copyWith(
        color: scheme.surfaceContainerHighest,
      ),
      bottomNavigationBarTheme: light().bottomNavigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.secondary,
        unselectedItemColor: scheme.onSurfaceVariant,
      ),
      snackBarTheme: light().snackBarTheme.copyWith(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      appBarTheme: light().appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      bottomSheetTheme: light().bottomSheetTheme.copyWith(
        backgroundColor: scheme.surface,
      ),
      listTileTheme: light().listTileTheme.copyWith(
        iconColor: scheme.onSurface,
        tileColor: scheme.surface,
      ),
      floatingActionButtonTheme: light().floatingActionButtonTheme.copyWith(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
      tabBarTheme: light().tabBarTheme.copyWith(
        labelColor: scheme.secondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.secondary, width: 2.5),
        ),
      ),
      tooltipTheme: light().tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      checkboxTheme: light().checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? scheme.secondary
                  : scheme.outlineVariant,
        ),
      ),
      switchTheme: light().switchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? scheme.secondary.withOpacity(0.5)
                  : scheme.outlineVariant,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? scheme.secondary
                  : scheme.onSurfaceVariant,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(scheme.secondary),
      ),
    );
  }
}

TextTheme _textThemeLight(TextTheme base) {
  final titles = GoogleFonts.merriweatherTextTheme(base).copyWith(
    titleLarge: GoogleFonts.merriweather(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
    titleMedium: GoogleFonts.merriweather(
      textStyle: base.titleMedium,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );
  final body = GoogleFonts.robotoTextTheme(base).copyWith(
    bodyLarge: GoogleFonts.roboto(textStyle: base.bodyLarge, height: 1.28),
    bodyMedium: GoogleFonts.roboto(textStyle: base.bodyMedium, height: 1.28),
    bodySmall: GoogleFonts.roboto(textStyle: base.bodySmall, height: 1.25),
  );
  // Merge titles into body, then tweak display/headlines to Merriweather
  final merged = body.copyWith(
    displayLarge: titles.displayLarge,
    displayMedium: titles.displayMedium,
    displaySmall: titles.displaySmall,
    headlineLarge: titles.headlineLarge,
    headlineMedium: titles.headlineMedium,
    headlineSmall: titles.headlineSmall,
    titleLarge: titles.titleLarge,
    titleMedium: titles.titleMedium,
    titleSmall: titles.titleSmall,
    labelLarge: body.labelLarge,
    labelMedium: body.labelMedium,
    labelSmall: body.labelSmall,
  );
  return merged;
}
