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
    this.allowLabel,
    this.denyLabel,
    this.openSettingsLabel,
    this.cancelLabel,
  });

  /// Short, localized headline (e.g. "Camera access").
  final String title;

  /// Localized body copy explaining why the permission is needed.
  final String description;

  /// Icon representing the permission.
  final IconData icon;

  /// Overrides the "Allow" button label for this specific call.
  /// Falls back to [PermissionTexts.allowButtonLabel] when null.
  final String? allowLabel;

  /// Overrides the "Deny" button label for this specific call.
  /// Falls back to [PermissionTexts.denyButtonLabel] when null.
  final String? denyLabel;

  /// Overrides the "Open Settings" button label in the permanently-denied sheet.
  /// Falls back to [PermissionTexts.openSettingsButtonLabel] when null.
  final String? openSettingsLabel;

  /// Overrides the "Cancel" button label in the permanently-denied sheet.
  /// Falls back to [PermissionTexts.cancelButtonLabel] when null.
  final String? cancelLabel;

  PermissionExplanation copyWith({
    String? title,
    String? description,
    IconData? icon,
    String? allowLabel,
    String? denyLabel,
    String? openSettingsLabel,
    String? cancelLabel,
  }) {
    return PermissionExplanation(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      allowLabel: allowLabel ?? this.allowLabel,
      denyLabel: denyLabel ?? this.denyLabel,
      openSettingsLabel: openSettingsLabel ?? this.openSettingsLabel,
      cancelLabel: cancelLabel ?? this.cancelLabel,
    );
  }

  @override
  List<Object?> get props => [
    title,
    description,
    icon,
    allowLabel,
    denyLabel,
    openSettingsLabel,
    cancelLabel,
  ];
}
