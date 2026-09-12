import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/name_icon_mapping.dart';

/// Resolves a backend-supplied Font Awesome CSS class string — e.g.
/// `"fa-solid fa-store"`, `"fa-sharp fa-solid fa-house"`,
/// `"fa-brands fa-google"` — into a Font Awesome [FaIconData], entirely at
/// presentation time.
///
/// The backend is the source of truth for which icon and style each card
/// shows. This resolver never hardcodes an icon-*name* mapping (`fa-store`
/// → `FontAwesomeIcons.store`); it only understands Font Awesome's CSS
/// *style* vocabulary (solid/regular/light/thin/brands/sharp-*) and looks
/// the icon name up in `faIconNameMapping`, which is generated wholesale by
/// the `font_awesome_flutter` configurator from Font Awesome's own metadata
/// (see `third_party/README.md`).
///
/// The package's own generated `getIconFromCss` cannot be used for this:
/// it only recognizes legacy short style tokens (`fas`/`far`/`fab`/`fal`/
/// `fat`) and has no notion of `fa-sharp`, so it can't parse the modern,
/// long-form CSS the backend actually sends.
///
/// Version boundary: this can only resolve an icon/style that exists in the
/// Font Awesome Pro version bundled with the installed app. A backend icon
/// newer than, or absent from, that bundle — or an unsupported style
/// (`duotone`/`sharp-duotone`, discontinued by this Flutter package) —
/// resolves to `null` here, never a crash.
abstract final class BackendIconResolver {
  BackendIconResolver._();

  static const Set<String> _weightStyles = {
    'solid',
    'regular',
    'light',
    'thin',
    'brands',
  };

  static const Map<String, String> _shortStyleTokens = {
    'fas': 'solid',
    'far': 'regular',
    'fab': 'brands',
    'fal': 'light',
    'fat': 'thin',
  };

  static const Set<String> _duotoneTokens = {'fa-duotone', 'duotone', 'fad'};

  /// Resolves [cssClasses] to its [FaIconData].
  ///
  /// Returns `null` when [cssClasses] is `null`/empty, malformed, names an
  /// unknown icon, or names a style this app's bundled Font Awesome version
  /// doesn't support (e.g. duotone). Never throws.
  static FaIconData? resolve(String? cssClasses) {
    if (cssClasses == null || cssClasses.trim().isEmpty) return null;

    try {
      final tokens = cssClasses
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();

      // Duotone / sharp-duotone are unsupported by this package version —
      // never silently substitute a different style for them.
      if (tokens.any(_duotoneTokens.contains)) return null;

      final isSharp = tokens.contains('fa-sharp') || tokens.contains('sharp');

      String? weight;
      for (final token in tokens) {
        final longForm = token.startsWith('fa-') ? token.substring(3) : token;
        if (_weightStyles.contains(longForm)) {
          weight = longForm;
          break;
        }
        if (_shortStyleTokens.containsKey(token)) {
          weight = _shortStyleTokens[token];
          break;
        }
      }
      // Font Awesome defaults to solid when a name is given without an
      // explicit weight class (matches browser/CSS behavior).
      weight ??= 'solid';

      final style = isSharp ? 'sharp $weight' : weight;

      String? name;
      for (final token in tokens) {
        if (!token.startsWith('fa-')) continue;
        final stripped = token.substring(3);
        if (stripped == 'sharp' || _weightStyles.contains(stripped)) continue;
        name = stripped;
        break;
      }
      if (name == null) return null;

      return faIconNameMapping['$style $name'];
    } on Object {
      return null;
    }
  }

  /// [resolve], falling back to [fallback] when the backend icon can't be
  /// resolved. Use this at call sites that need a always-non-null icon.
  static FaIconData resolveOrFallback(
    String? cssClasses, {
    FaIconData fallback = FontAwesomeIcons.solidCircleQuestion,
  }) => resolve(cssClasses) ?? fallback;
}
