import 'package:authorization/src/domain/permission_requirement.dart';
import 'package:authorization/src/presentation/permission_builder.dart';
import 'package:authorization/src/reader/authorization_reader.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// The shared, feature-agnostic authorization primitive: "show this widget
/// only if the user can do X."
///
/// [PermissionGate] knows only about a permission requirement and a
/// hide/disable/fallback strategy — it has no knowledge of *why* a
/// permission exists or what business rule it maps to. That distinction
/// belongs to the calling feature (see the package README, "Permission vs
/// rule vs business rule").
///
/// Exactly one of hide/disable is active per instance, selected by
/// [disabled]:
/// - `disabled: false` (default) — denied ⇒ render [fallback] (or nothing).
///   Use this for actions that should be entirely absent for an unauthorized
///   user, e.g. an "Add Branch" button a view-only worker should never see.
/// - `disabled: true` — denied ⇒ render [child] wrapped in [IgnorePointer] +
///   dimmed [Opacity], so the control stays visible but inert. Use this when
///   a workflow benefits from showing what exists but cannot be used.
///
/// This widget never evaluates business rules (branch ownership, maintenance
/// state, etc.) — only the permission requirement passed to it.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    required this.permission,
    required this.child,
    super.key,
    this.fallback,
    this.disabled = false,
    this.disabledOpacity = AppOpacities.disabled,
    this.reader,
  });

  /// Convenience constructor for an `any`/`all` composed requirement.
  const PermissionGate.requiring({
    required PermissionRequirement requirement,
    required this.child,
    super.key,
    this.fallback,
    this.disabled = false,
    this.disabledOpacity = AppOpacities.disabled,
    this.reader,
  }) : permission = requirement;

  /// A single action string, or a composed [PermissionRequirement] (via
  /// [PermissionGate.requiring]).
  final Object permission;

  final Widget child;

  /// Rendered instead of [child] when denied and [disabled] is `false`.
  /// Defaults to nothing (`SizedBox.shrink()`).
  final Widget? fallback;

  final bool disabled;

  /// Opacity applied to [child] when denied and [disabled] is `true`.
  final double disabledOpacity;

  /// Override for testing. Defaults to the DI-registered singleton.
  final AuthorizationReader? reader;

  PermissionRequirement get _requirement => switch (permission) {
    final PermissionRequirement r => r,
    final String action => PermissionRequirement.single(action),
    _ => throw ArgumentError(
      'PermissionGate.permission must be a String action or a '
      'PermissionRequirement, got ${permission.runtimeType}.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      requirement: _requirement,
      reader: reader,
      builder: (context, allowed) {
        if (allowed) return child;
        if (disabled) {
          return IgnorePointer(
            child: Opacity(opacity: disabledOpacity, child: child),
          );
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
