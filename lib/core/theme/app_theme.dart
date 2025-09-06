import 'package:flutter/material.dart';

class AppTheme {
  // Asunción: color de marca basado en librerías/lectura (tono teal/verde-azulado).
  // Puedes cambiar seed a juego con assets/design sin tocar el resto del código.
  static const Color _brandSeed = Color(0xFF0E938C); // teal profundo

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandSeed,
      brightness: Brightness.light,
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
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.25),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.25),
      ),
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
        fillColor: MaterialStateProperty.resolveWith(
          (s) =>
              s.contains(MaterialState.selected)
                  ? scheme.primary
                  : scheme.outlineVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith(
          (s) =>
              s.contains(MaterialState.selected)
                  ? scheme.primary.withOpacity(0.5)
                  : scheme.outlineVariant,
        ),
        thumbColor: MaterialStateProperty.resolveWith(
          (s) =>
              s.contains(MaterialState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(scheme.primary),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandSeed,
      brightness: Brightness.dark,
    );
    // Theme base no es necesario porque partimos de light().copyWith.
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
        fillColor: MaterialStateProperty.resolveWith(
          (s) =>
              s.contains(MaterialState.selected)
                  ? scheme.secondary
                  : scheme.outlineVariant,
        ),
      ),
      switchTheme: light().switchTheme.copyWith(
        trackColor: MaterialStateProperty.resolveWith(
          (s) =>
              s.contains(MaterialState.selected)
                  ? scheme.secondary.withOpacity(0.5)
                  : scheme.outlineVariant,
        ),
        thumbColor: MaterialStateProperty.resolveWith(
          (s) =>
              s.contains(MaterialState.selected)
                  ? scheme.secondary
                  : scheme.onSurfaceVariant,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(scheme.secondary),
      ),
    );
  }
}
