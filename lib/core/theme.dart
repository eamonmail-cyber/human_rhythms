import 'package:flutter/material.dart';

// ── Human Rhythms Design System ──────────────────────────────────────────────
const kPrimary     = Color(0xFF00897B);
const kPrimaryDark = Color(0xFF005F56);
const kPrimaryLight= Color(0xFF4DB6AC);
const kAccent      = Color(0xFFFF6B6B);
const kSurface     = Color(0xFFF7FAF9);
const kCard        = Color(0xFFFFFFFF);
const kTextDark    = Color(0xFF1A2E2C);
const kTextMid     = Color(0xFF4A6360);
const kTextLight   = Color(0xFF8AADAA);
const kDivider     = Color(0xFFE0EDEB);

const kCatSleep      = Color(0xFF5B8DEF);
const kCatMovement   = Color(0xFF26C6A6);
const kCatFood       = Color(0xFFFFB300);
const kCatMind       = Color(0xFF9575CD);
const kCatSocial     = Color(0xFFFF7043);
const kCatWork       = Color(0xFF29B6F6);
const kCatHealth     = Color(0xFFEC407A);
const kCatReflection = Color(0xFF78909C);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      secondary: kAccent,
      surface: kSurface,
      onPrimary: Colors.white,
      onSurface: kTextDark,
    ),
    scaffoldBackgroundColor: kSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: kDivider,
      iconTheme: IconThemeData(color: kTextDark),
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, color: kTextDark, letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: kCard, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kDivider, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary, side: const BorderSide(color: kPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: kCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDivider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
      labelStyle: const TextStyle(color: kTextMid),
      hintStyle: const TextStyle(color: kTextLight),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurface, selectedColor: kPrimary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: kDivider),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCard, selectedItemColor: kPrimary, unselectedItemColor: kTextLight,
      elevation: 8, type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(fontWeight: FontWeight.w800, color: kTextDark, fontSize: 26),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 22),
      titleLarge:     TextStyle(fontWeight: FontWeight.w700, color: kTextDark, fontSize: 18),
      titleMedium:    TextStyle(fontWeight: FontWeight.w600, color: kTextDark, fontSize: 16),
      titleSmall:     TextStyle(fontWeight: FontWeight.w600, color: kTextMid,  fontSize: 12, letterSpacing: 0.8),
      bodyLarge:      TextStyle(color: kTextDark, fontSize: 15),
      bodyMedium:     TextStyle(color: kTextMid,  fontSize: 14),
      labelLarge:     TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

// ── HRLogo ────────────────────────────────────────────────────────────────────
class HRLogo extends StatelessWidget {
  final double size;
  final bool light;
  const HRLogo({super.key, required this.size, this.light = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HRLogoPainter(light: light),
    );
  }
}

class _HRLogoPainter extends CustomPainter {
  final bool light;
  const _HRLogoPainter({required this.light});

  @override
  void paint(Canvas canvas, Size size) {
    final color = light ? Colors.white : const Color(0xFF00897B);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final r = size.width * 0.28;
    final cy = size.height * 0.5;
    // Two overlapping circles
    canvas.drawCircle(Offset(size.width * 0.38, cy), r, paint);
    canvas.drawCircle(Offset(size.width * 0.62, cy), r, paint);

    // Heartbeat / pulse line through centre
    final midY = cy;
    final path = Path()
      ..moveTo(size.width * 0.05, midY)
      ..lineTo(size.width * 0.30, midY)
      ..lineTo(size.width * 0.38, midY - size.height * 0.20)
      ..lineTo(size.width * 0.46, midY + size.height * 0.20)
      ..lineTo(size.width * 0.54, midY - size.height * 0.10)
      ..lineTo(size.width * 0.60, midY)
      ..lineTo(size.width * 0.95, midY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HRLogoPainter old) => old.light != light;
}
