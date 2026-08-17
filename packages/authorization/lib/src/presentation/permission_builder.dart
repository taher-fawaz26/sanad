import 'package:authorization/src/domain/permission_requirement.dart';
import 'package:authorization/src/reader/authorization_reader.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] whenever the [reader]'s decision for [requirement]
/// changes. The lowest-level authorization-aware primitive — `PermissionGate`
/// is built on top of this for the common hide/disable/fallback cases;
/// reach for this directly when a surface needs a bespoke reaction to an
/// authorization decision (e.g. custom empty-state copy for a view-only user).
///
/// Feature-agnostic by construction: this widget knows only about a
/// permission requirement and a boolean outcome, never about *why* a
/// permission exists or what business rule it maps to.
class PermissionBuilder extends StatefulWidget {
  const PermissionBuilder({
    required this.requirement,
    required this.builder,
    super.key,
    this.reader,
  });

  final PermissionRequirement requirement;

  /// `allowed` is `false` while the reader is unresolved — the same
  /// fail-open-on-indeterminate stance used for route guards (an unresolved
  /// session is not a denial). Callers wanting to distinguish "denied" from
  /// "unknown" should read [AuthorizationReader.isResolved] directly via
  /// [reader].
  // Positional `bool` matches the standard Flutter builder-callback shape
  // (e.g. AnimatedBuilder, ValueListenableBuilder) — named would be atypical
  // at a call site that always reads as `builder: (context, allowed) => ...`.
  // ignore: avoid_positional_boolean_parameters
  final Widget Function(BuildContext context, bool allowed) builder;

  /// Override for testing. Defaults to the DI-registered singleton.
  final AuthorizationReader? reader;

  @override
  State<PermissionBuilder> createState() => _PermissionBuilderState();
}

class _PermissionBuilderState extends State<PermissionBuilder> {
  late final AuthorizationReader _reader;
  late bool _allowed;

  @override
  void initState() {
    super.initState();
    _reader = widget.reader ?? sl<AuthorizationReader>();
    _allowed = _evaluate();
    _reader.addListener(_onAuthorizationChanged);
  }

  // AuthorizationReader.satisfies already folds in isResolved — see its doc
  // comment — so no separate unresolved check is needed here.
  bool _evaluate() => _reader.satisfies(widget.requirement);

  void _onAuthorizationChanged() {
    final next = _evaluate();
    if (next != _allowed) {
      setState(() => _allowed = next);
    }
  }

  @override
  void dispose() {
    _reader.removeListener(_onAuthorizationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _allowed);
}
