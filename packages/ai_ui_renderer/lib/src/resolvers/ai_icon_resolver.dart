import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Turns a protocol `icon.name` into a widget.
///
/// Two sources, in order:
///   1. [tokens] — SANAD's own short names (`calendar`, `branch`), which keep
///      the agent's vocabulary small, stable and tree-shakeable.
///   2. [BackendIconResolver] — Font Awesome CSS classes
///      (`"fa-solid fa-store"`), reusing the resolver the rest of the app
///      already uses for backend-supplied icons.
///
/// It returns a `Widget` rather than an `IconData` because the two sources are
/// not the same type: Font Awesome's `FaIconData` is a standalone class, not
/// an `IconData`, and needs `FaIcon` rather than `Icon`. Keeping that choice
/// here means no renderer has to know which source a name came from.
///
/// Unknown names return `null` and the icon is omitted — the same contract as
/// `BackendIconResolver`, which never throws.
///
/// Build consequence of source 2: resolving Font Awesome icons by name defeats
/// icon tree-shaking, so a release build that enables it needs
/// `--no-tree-shake-icons`, the constraint `sanad_provider` already carries.
/// Pass `allowFontAwesome: false` to stay on the token map and avoid it.
final class AiIconResolver extends Equatable {
  const AiIconResolver({
    this.tokens = const {},
    this.allowFontAwesome = true,
  });

  final Map<String, IconData> tokens;
  final bool allowFontAwesome;

  bool canResolve(String name) =>
      tokens.containsKey(name) ||
      (allowFontAwesome && BackendIconResolver.resolve(name) != null);

  Widget? build(String name, {double? size, Color? color}) {
    final token = tokens[name];
    if (token != null) return Icon(token, size: size, color: color);

    if (!allowFontAwesome) return null;
    final faIcon = BackendIconResolver.resolve(name);
    if (faIcon == null) return null;
    return FaIcon(faIcon, size: size, color: color);
  }

  @override
  List<Object?> get props => [tokens, allowFontAwesome];
}
