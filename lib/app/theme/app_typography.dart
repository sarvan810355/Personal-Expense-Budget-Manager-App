import 'package:flutter/material.dart';

/// Central text theme overrides layered on top of Material 3 defaults.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
