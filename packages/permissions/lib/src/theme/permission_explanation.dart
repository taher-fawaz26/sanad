import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// A fully-configurable, localization-friendly explanation for a single
/// permission.
///
/// Nothing is hardcoded — the caller supplies already-localized strings and an
/// icon, so the same model works for any locale:
///
/// ```dart
/// PermissionExplanation(
///   title: context.l10n.cameraPermission,
///   description: context.l10n.cameraPermissionDescription,
///   icon: AppIcons.camera,
/// )
/// ```
///
/// Explanations can be registered per [PermissionType] on [PermissionTheme]
/// and/or overridden per-call by a feature.
class PermissionExplanation extends Equatable {
  const PermissionExplanation({
    required this.title,
    required this.description,
    required this.icon,
  });

  /// Short, localized headline (e.g. "Camera access").
  final String title;

  /// Localized body copy explaining why the permission is needed.
  final String description;

  /// Icon representing the permission.
  final IconData icon;

  PermissionExplanation copyWith({
    String? title,
    String? description,
    IconData? icon,
  }) {
    return PermissionExplanation(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  @override
  List<Object?> get props => [title, description, icon];
}
