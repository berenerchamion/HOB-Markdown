import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class AppTheme {
  // Primary seed color (Modern Indigo Blue)
  static const Color primarySeed = Color(0xFF2563EB);

  /// Bundled font families (see `fonts:` in pubspec.yaml). Because they're
  /// registered with every weight, `copyWith(fontWeight: ...)` picks the
  /// real face instead of a synthesized bold.
  static const String uiFontFamily = 'Inter';
  static const String codeFontFamily = 'JetBrainsMono';

  /// Monospace style for code: the editor, code blocks and inline code.
  static TextStyle codeStyle({
    double? fontSize,
    double? height,
    Color? color,
  }) => TextStyle(
    fontFamily: codeFontFamily,
    fontSize: fontSize,
    height: height,
    color: color,
  );

  /// Built once and reused. Building a theme is expensive (the seed colour
  /// scheme alone is a lot of colour maths), and `MarkdownReaderApp` asks for
  /// both themes every time the controller changes. Rebuilding them also made
  /// every theme-dependent widget, like the rendered Markdown, think the
  /// theme had changed and redo its work.
  static ThemeData lightTheme() => _light;
  static ThemeData darkTheme() => _dark;

  static final ThemeData _light = _buildLightTheme();
  static final ThemeData _dark = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC), // Slate 50
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF1F5F9), // Slate 100
      surfaceContainer: const Color(0xFFE2E8F0), // Slate 200
      surfaceContainerHigh: const Color(0xFFCBD5E1), // Slate 300
      surfaceContainerHighest: const Color(0xFF94A3B8), // Slate 400
      onSurface: const Color(0xFF0F172A), // Slate 900
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: uiFontFamily,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F172A), // Slate 900
      surfaceContainerLowest: const Color(0xFF090D16), // Slate 950
      surfaceContainerLow: const Color(0xFF1E293B), // Slate 800
      surfaceContainer: const Color(0xFF334155), // Slate 700
      surfaceContainerHigh: const Color(0xFF475569), // Slate 600
      surfaceContainerHighest: const Color(0xFF64748B), // Slate 500
      onSurface: const Color(0xFFF8FAFC), // Slate 50
      outline: const Color(0xFF475569),
      outlineVariant: const Color(0xFF334155),
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: uiFontFamily,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  /// Builds a rich Material Design 3 style sheet for rendered Markdown.
  static MarkdownStyleSheet markdownStyleSheet(
    BuildContext context, {
    required double scaleFactor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final codeFont = codeStyle();

    final Color bodyColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF334155);
    final Color headingColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final Color inlineCodeBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final Color blockquoteBar = colorScheme.primary;
    final Color blockquoteBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9).withValues(alpha: 0.8);

    return MarkdownStyleSheet(
      // Headings (H1 to H6)
      // Semibold throughout, with size carrying the hierarchy, as macOS
      // documents do. Inter's real Bold and ExtraBold read as heavy at
      // these sizes.
      h1: TextStyle(
        fontSize: 28 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: headingColor,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      h1Padding: const EdgeInsets.only(top: 28, bottom: 14),
      h2: TextStyle(
        fontSize: 22 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: headingColor,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      h2Padding: const EdgeInsets.only(top: 24, bottom: 12),
      h3: TextStyle(
        fontSize: 18 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: headingColor,
        height: 1.3,
      ),
      h3Padding: const EdgeInsets.only(top: 20, bottom: 10),
      h4: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: headingColor,
      ),
      h4Padding: const EdgeInsets.only(top: 16, bottom: 8),
      h5: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: headingColor,
      ),
      h6: TextStyle(
        fontSize: 13 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),

      // Paragraphs & Prose
      p: TextStyle(
        fontSize: 16 * scaleFactor,
        color: bodyColor,
        height: 1.7,
        letterSpacing: 0.1,
      ),
      pPadding: const EdgeInsets.only(bottom: 14),

      // Strong / Emphasis
      strong: TextStyle(fontWeight: FontWeight.w700, color: headingColor),
      em: const TextStyle(fontStyle: FontStyle.italic),

      // Links
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: colorScheme.primary.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
      ),

      // Inline Code
      code: codeFont.copyWith(
        fontSize: 14 * scaleFactor,
        backgroundColor: inlineCodeBg,
        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      ),

      // Blockquotes
      blockquote: TextStyle(
        fontSize: 15.5 * scaleFactor,
        fontStyle: FontStyle.italic,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        height: 1.6,
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      blockquoteDecoration: BoxDecoration(
        color: blockquoteBg,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        border: Border(left: BorderSide(color: blockquoteBar, width: 4)),
      ),

      // Lists
      listBullet: TextStyle(
        fontSize: 16 * scaleFactor,
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      listBulletPadding: const EdgeInsets.only(right: 10),

      // Horizontal Rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
        ),
      ),

      // Tables
      tableHead: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w700,
        color: headingColor,
      ),
      tableBody: TextStyle(fontSize: 14 * scaleFactor, color: bodyColor),
      tableHeadAlign: TextAlign.left,
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
        width: 1,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
    );
  }
}
