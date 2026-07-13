/// **Arabic typography line-height scale — design tokens `arabic.*`.**
///
/// Arabic text requires taller line heights than English for vowel marks and
/// descenders. Do not reuse [TypeScale] English line heights for Arabic.
///
/// Font sizes are shared with [TypeScale]; only line heights differ.
abstract final class ArabicTypeScale {
  ArabicTypeScale._();

  // ── Titles ────────────────────────────────────────────────────────────────
  static const double lineHeightTitle1 = 60 / 48;
  static const double lineHeightTitle2 = 44 / 32;
  static const double lineHeightTitle3 = 36 / 24;

  // ── Large (18) ─────────────────────────────────────────────────────────
  static const double lineHeightLargeNone = 1;
  static const double lineHeightLargeTight = 20 / 18;
  static const double lineHeightLargeNormal = 28 / 18;

  // ── Regular (16) ──────────────────────────────────────────────────────────
  static const double lineHeightRegularNone = 1;
  static const double lineHeightRegularTight = 20 / 16;
  static const double lineHeightRegularNormal = 26 / 16;

  // ── Small (14) ────────────────────────────────────────────────────────────
  static const double lineHeightSmallNone = 1;
  static const double lineHeightSmallTight = 16 / 14;
  static const double lineHeightSmallNormal = 22 / 14;

  // ── Tiny (12) ─────────────────────────────────────────────────────────────
  static const double lineHeightTinyNone = 1;
  static const double lineHeightTinyTight = 14 / 12;
  static const double lineHeightTinyNormal = 20 / 12;
}
