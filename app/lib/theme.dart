import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Kente-Modernist palette ───────────────────────────────────────────────
// Grayscale structure + a single vibrant accent (terracotta) reserved for CTAs.
const Color charcoal = Color(0xFF2B2B2D); // primary text / strong structure
const Color slate = Color(0xFF5A5E63); // secondary text / muted accents
const Color silver = Color(0xFFC9CCD1); // borders, Kente mid-tone
const Color silverLight = Color(0xFFE7E9EC); // hairlines, faint Kente
const Color terracotta = Color(0xFFE2725B); // THE accent — illustration/icons
// Deeper terracotta for FILLED CTA backgrounds: white text on this is ~4.7:1,
// clearing WCAG AA (the lighter terracotta is only ~3.1:1 and fails on buttons).
const Color terracottaDeep = Color(0xFFBE5235);

// ── Legacy aliases (remapped to the grayscale system so screens compile) ──
const Color ink = charcoal;
const Color inkSoft = slate;
const Color canvas = Color(0xFFFFFFFF); // crisp white background
const Color sand = canvas;
const Color surfaceCard = Color(0xFFFFFFFF);
const Color hairline = silverLight;
const Color glyphTile = Color(0xFFF1F2F4); // neutral tile behind glyphs
const Color accentCoral = terracotta;
const Color plantainGreen = slate; // formerly green → neutral structural tone
const Color plantainDeep = charcoal; // formerly deep green → charcoal

// ── Shape (Apple-style squircle) ──────────────────────────────────────────
const ShapeBorder kSquircleCard =
    ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30)));
const RoundedRectangleBorder kButtonShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)));

// Soft, neutral elevation tuned for a white background.
const List<BoxShadow> kSoftShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
  BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
];

// ── Type system ───────────────────────────────────────────────────────────
// Two faces, one job each: Space Grotesk carries the display/heading voice
// (characterful, a touch geometric), Inter carries body + UI (neutral, legible,
// and — crucially — it draws the Twi glyphs ɔ/ɛ). Space Grotesk has a limited
// character set, so Inter is registered as a per-glyph fallback: any character
// Space Grotesk can't render falls to Inter instead of an OS default.
List<String>? _headingFallback() {
  final f = GoogleFonts.inter().fontFamily;
  return f != null ? <String>[f] : null;
}

/// Space Grotesk display/heading style with an Inter fallback for Twi glyphs.
/// Headings want tight tracking and tight leading — the defaults reflect that.
TextStyle displayFont({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = charcoal,
  double height = 1.1,
  double letterSpacing = -0.4,
}) {
  return GoogleFonts.spaceGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: _headingFallback());
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: terracotta,
    primary: terracotta,
    surface: canvas,
    brightness: Brightness.light,
  ).copyWith(onPrimary: Colors.white);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: charcoal,
    displayColor: charcoal,
  );

  // Headings (display/headline/title) speak Space Grotesk; body/label stay
  // Inter. Tight leading on the big sizes, a clear step above body — this is
  // where the "premium, not default" hierarchy lives.
  final fb = _headingFallback();
  TextStyle head(TextStyle? b, FontWeight w, double h, [double ls = -0.4]) =>
      GoogleFonts.spaceGrotesk(textStyle: b, fontWeight: w, height: h, letterSpacing: ls)
          .copyWith(color: charcoal, fontFamilyFallback: fb);
  final text2 = text.copyWith(
    displayLarge: head(text.displayLarge, FontWeight.w600, 1.04),
    displayMedium: head(text.displayMedium, FontWeight.w600, 1.05),
    displaySmall: head(text.displaySmall, FontWeight.w600, 1.07),
    headlineLarge: head(text.headlineLarge, FontWeight.w600, 1.08),
    headlineMedium: head(text.headlineMedium, FontWeight.w600, 1.12),
    headlineSmall: head(text.headlineSmall, FontWeight.w600, 1.15),
    titleLarge: head(text.titleLarge, FontWeight.w700, 1.2, -0.2),
  );

  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    textTheme: text2,
    splashColor: charcoal.withValues(alpha: 0.05),
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: displayFont(
          fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    ),
    // Primary CTA — deeper terracotta so white label meets WCAG AA contrast.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: terracottaDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: kButtonShape,
        padding: const EdgeInsets.symmetric(vertical: 17),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: charcoal,
        side: const BorderSide(color: silver),
        shape: kButtonShape,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: charcoal,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    // Velvet-dark nav shell: terracotta for the active tab, ochre indicator.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF17130F),
      elevation: 0,
      height: 66,
      indicatorColor: const Color(0x33D4A373),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF3ECE4)),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
            color: selected ? terracotta : const Color(0xFF9B8F86));
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAFAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: silver),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: silver),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: charcoal, width: 1.6),
      ),
      labelStyle: const TextStyle(color: slate),
    ),
    dividerTheme: const DividerThemeData(color: silverLight, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: charcoal,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
