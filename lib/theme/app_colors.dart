import 'package:flutter/material.dart';

class AppColors {
  // ── Dark Background Layer ──────────────────────────────────────────────────
  static const Color background    = Color(0xFF080D0A);  // Near-black with emerald undertone
  static const Color surface       = Color(0xFF0D1510);  // Deep midnight green-black
  static const Color surfaceLight  = Color(0xFF152018);  // Slightly lifted card surface

  // ── Brand Primary: Emerald Green (Logo Wings / Left Body) ─────────────────
  // Inspired by the dominant deep emerald green of the logo's wings.
  // Used for: Primary CTAs, highlights, active nav, glows.
  static const Color brandGreen    = Color(0xFF2ECC71);  // Vibrant emerald — primary accent
  static const Color forestGreen   = Color(0xFF1B8A4E);  // Deep forest — gradient anchor
  static const Color darkGreen     = Color(0xFF145E35);  // Darkest wing shadow tone

  // ── Brand Secondary: Sapphire Blue (Logo Bird Head / Neck) ────────────────
  // Taken from the logo's rich sapphire-blue head region.
  // Used for: Secondary actions, info states, electric glow effects.
  static const Color brandBlue     = Color(0xFF1A6BB5);  // Royal sapphire — secondary accent
  static const Color oceanBlue     = Color(0xFF1565C0);  // Deep ocean — gradient anchor
  static const Color skyBlue       = Color(0xFF2196F3);  // Lighter pop for hover states

  // ── Teal Bridge (Logo Neck/Transition Zone) ────────────────────────────────
  // Where green and blue merge in the logo — the "trust bridge" color.
  // Used for: Card borders, dividers, subtle glows, tag backgrounds.
  static const Color teal          = Color(0xFF20A882);  // Logo teal bridge
  static const Color deepTeal      = Color(0xFF148A67);  // Darker teal for shadow/depth

  // ── Legacy aliases (backward-compatible — maps to brand palette) ──────────
  static const Color cyan          = teal;            // Replaces old #00B4FF cyan
  static const Color electricBlue  = brandBlue;       // Replaces old #3B82F6 blue

  // ── Semantic / Functional Colors ──────────────────────────────────────────
  static const Color success       = Color(0xFF27AE60);  // Forest-harmonized success green
  static const Color error         = Color(0xFFEF4444);  // Error red (unchanged)
  static const Color warning       = Color(0xFFFBBF24);  // Amber warning (unchanged)
  static const Color info          = brandBlue;           // Routes to sapphire blue
  static const Color orange        = Color(0xFFF59E0B);
  static const Color accentGold    = Color(0xFFFFD700);

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted     = Color(0xFF6B7280);

  // ── Legacy mappings ───────────────────────────────────────────────────────
  static const Color buyerGreen    = success;
  static const Color sellerBlue    = brandBlue;
  static const Color dark          = background;
  static const Color muted         = textSecondary;

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Primary logo gradient — Emerald→Sapphire, mirrors the logo's own color flow
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandGreen, brandBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Full brand sweep — deep forest green → teal → deep ocean blue
  static const LinearGradient brandGradient = LinearGradient(
    colors: [forestGreen, teal, oceanBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Subtle surface gradient for hero backgrounds / section backdrops
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080D0A), Color(0xFF0A1A12), Color(0xFF080D0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [orange, accentGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Box Decoration Helpers ─────────────────────────────────────────────────

  /// Gradient button/badge box with emerald glow shadow
  static BoxDecoration gradientBox({double radius = 12}) => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: brandGreen.withOpacity(0.35),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );

  /// Cyber card — deep surface with teal-tinted border (matches logo teal bridge)
  static BoxDecoration cyberCard({double radius = 16}) => BoxDecoration(
    color: surface.withOpacity(0.7),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: teal.withOpacity(0.18)),
    boxShadow: [
      BoxShadow(
        color: teal.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  /// Premium glow card with stronger sapphire-blue edge for key info panels
  static BoxDecoration premiumCard({double radius = 20}) => BoxDecoration(
    color: surface.withOpacity(0.8),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: brandBlue.withOpacity(0.25)),
    boxShadow: [
      BoxShadow(
        color: brandBlue.withOpacity(0.08),
        blurRadius: 30,
        spreadRadius: 4,
      ),
    ],
  );
}
