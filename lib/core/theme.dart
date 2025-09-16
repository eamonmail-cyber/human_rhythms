import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2E7D32),
    brightness: Brightness.light,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontSizeFactor: 1.02),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
