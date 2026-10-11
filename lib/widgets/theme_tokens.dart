/// CapitalFlow Design System — Theme Tokens
///
/// Standalone file. Zero imports from the full app.
/// Copy-paste safe for evaluation purposes.
///
/// Contains: color palette, typography scale, spacing scale, border radii,
/// elevation levels, and the full ThemeData factory.
library capitalflow_theme;

import 'package:flutter/material.dart';

// ── Color Palette ─────────────────────────────────────────────────────────────

class CFColors {
  CFColors._();

  // Brand
  static const Color brandBlue      = Color(0xFF2563EB); // Primary CTA
  static const Color brandBlueDark  = Color(0xFF1D4ED8);
  static const Color brandBlueLight = Color(0xFF3B82F6);

  // Surface (dark theme)
  static const Color background     = Color(0xFF0A0E1A); // Deepest bg
  static const Color surface        = Color(0xFF111827); // Cards
  static const Color surfaceVariant = Color(0xFF1F2937); // Elevated cards
  static const Color outline        = Color(0xFF374151); // Dividers, borders

  // Semantic
  static const Color gain           = Color(0xFF10B981); // Green — profit
  static const Color loss           = Color(0xFFEF4444); // Red — loss
  static const Color warning        = Color(0xFFF59E0B); // Amber — pending
  static const Color info           = Color(0xFF3B82F6); // Blue — neutral info

  // IPO Status
  static const Color statusLive     = Color(0xFF10B981); // Green
  static const Color statusUpcoming = Color(0xFF3B82F6); // Blue
  static const Color statusClosed   = Color(0xFF6B7280); // Grey
  static const Color statusListed   = Color(0xFF8B5CF6); // Purple

  // Text
  static const Color textPrimary    = Color(0xFFF9FAFB);
  static const Color textSecondary  = Color(0xFF9CA3AF);
  static const Color textDisabled   = Color(0xFF4B5563);

  // Overlays
  static const Color overlayLight   = Color(0x14FFFFFF); // 8% white
  static const Color overlayDark    = Color(0x29000000); // 16% black
}

// ── Typography Scale ──────────────────────────────────────────────────────────

class CFTextStyles {
  CFTextStyles._();

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: CFColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: CFColors.textPrimary, letterSpacing: -0.3,
  );

  // Headings
  static const TextStyle headingLarge = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600,
    color: CFColors.textPrimary,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: CFColors.textPrimary,
  );
  static const TextStyle headingSmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: CFColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: CFColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: CFColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: CFColors.textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: CFColors.textPrimary,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: CFColors.textSecondary,
    letterSpacing: 0.3,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: CFColors.textSecondary,
    letterSpacing: 0.5,
  );

  // Monospace (prices, numbers)
  static const TextStyle mono = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    fontFamily: 'monospace', color: CFColors.textPrimary,
  );
  static const TextStyle monoPrimary = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    fontFamily: 'monospace', color: CFColors.textPrimary,
  );
}

// ── Spacing Scale ─────────────────────────────────────────────────────────────

class CFSpacing {
  CFSpacing._();

  static const double xs  =  4.0;
  static const double sm  =  8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// ── Border Radii ──────────────────────────────────────────────────────────────

class CFRadius {
  CFRadius._();

  static const double sm  =  6.0;
  static const double md  = 10.0;
  static const double lg  = 14.0;
  static const double xl  = 18.0;
  static const double pill = 100.0;

  static BorderRadius smAll  = BorderRadius.circular(sm);
  static BorderRadius mdAll  = BorderRadius.circular(md);
  static BorderRadius lgAll  = BorderRadius.circular(lg);
  static BorderRadius xlAll  = BorderRadius.circular(xl);
  static BorderRadius pillAll = BorderRadius.circular(pill);
}

// ── ThemeData Factory ─────────────────────────────────────────────────────────

class CFTheme {
  CFTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CFColors.background,
      colorScheme: ColorScheme.dark(
        primary:          CFColors.brandBlue,
        onPrimary:        CFColors.textPrimary,
        secondary:        CFColors.brandBlueLight,
        surface:          CFColors.surface,
        surfaceContainerHighest: CFColors.surfaceVariant,
        outline:          CFColors.outline,
        error:            CFColors.loss,
        onSurface:        CFColors.textPrimary,
        onSurfaceVariant: CFColors.textSecondary,
      ),
      cardTheme: CardTheme(
        color:            CFColors.surface,
        elevation:        0,
        shape:            RoundedRectangleBorder(
          borderRadius:   CFRadius.lgAll,
          side: const BorderSide(color: CFColors.outline, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:   CFColors.brandBlue,
          foregroundColor:   CFColors.textPrimary,
          shape:             RoundedRectangleBorder(borderRadius: CFRadius.mdAll),
          padding:           const EdgeInsets.symmetric(
            horizontal: CFSpacing.lg, vertical: CFSpacing.md,
          ),
          textStyle:         CFTextStyles.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:   CFColors.surfaceVariant,
        selectedColor:     CFColors.brandBlue.withValues(alpha: 0.2),
        labelStyle:        CFTextStyles.labelMedium,
        padding:           const EdgeInsets.symmetric(horizontal: CFSpacing.md),
        shape:             RoundedRectangleBorder(borderRadius: CFRadius.pillAll),
        side:              const BorderSide(color: CFColors.outline, width: 0.5),
      ),
      dividerTheme: const DividerThemeData(
        color: CFColors.outline,
        thickness: 0.5,
      ),
      iconTheme: const IconThemeData(
        color: CFColors.textSecondary,
        size: 20,
      ),
    );
  }
}
