import 'package:flutter/material.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/theme/permission_explanation.dart';

/// Default text content used by the permission dialogs.
///
/// Override any field to customise wording without replacing the whole theme.
class PermissionTexts {
  const PermissionTexts({
    this.rationaleDefaultTitle = 'Permission Required',
    this.rationaleDefaultMessage =
        'This permission is required for the feature to work correctly.',
    this.settingsTitle = 'Permission Denied',
    this.settingsMessage =
        'You have permanently denied this permission. '
        'Please enable it in your device settings to continue.',
    this.allowButtonLabel = 'Allow',
    this.denyButtonLabel = 'Not Now',
    this.openSettingsButtonLabel = 'Open Settings',
    this.cancelButtonLabel = 'Cancel',
    this.rationaleMessages = const {},
  });

  final String rationaleDefaultTitle;
  final String rationaleDefaultMessage;
  final String settingsTitle;
  final String settingsMessage;
  final String allowButtonLabel;
  final String denyButtonLabel;
  final String openSettingsButtonLabel;
  final String cancelButtonLabel;

  /// Per-permission rationale overrides. Falls back to
  /// [rationaleDefaultTitle] / [rationaleDefaultMessage] when absent.
  final Map<PermissionType, PermissionRationaleText> rationaleMessages;

  PermissionRationaleText rationaleFor(PermissionType type) {
    return rationaleMessages[type] ??
        PermissionRationaleText(
          title: rationaleDefaultTitle,
          message: rationaleDefaultMessage,
        );
  }
}

/// Custom rationale title + message for a single [PermissionType].
class PermissionRationaleText {
  const PermissionRationaleText({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;
}

/// Maps each [PermissionType] to an icon for display in the permission dialogs.
///
/// Override individual fields to use custom icons from your asset library.
class PermissionIcons {
  const PermissionIcons({
    this.camera = Icons.camera_alt_outlined,
    this.photos = Icons.photo_library_outlined,
    this.storage = Icons.folder_outlined,
    this.documents = Icons.description_outlined,
    this.microphone = Icons.mic_outlined,
    this.location = Icons.location_on_outlined,
    this.notifications = Icons.notifications_outlined,
    this.contacts = Icons.contacts_outlined,
    this.calendar = Icons.calendar_today_outlined,
    this.bluetooth = Icons.bluetooth_outlined,
    this.nearbyDevices = Icons.devices_outlined,
    this.phone = Icons.phone_outlined,
    this.mediaLibrary = Icons.library_music_outlined,
    this.fallback = Icons.lock_outlined,
  });

  final IconData camera;
  final IconData photos;
  final IconData storage;
  final IconData documents;
  final IconData microphone;
  final IconData location;
  final IconData notifications;
  final IconData contacts;
  final IconData calendar;
  final IconData bluetooth;
  final IconData nearbyDevices;
  final IconData phone;
  final IconData mediaLibrary;
  final IconData fallback;

  /// Returns the icon for the given [PermissionType].
  IconData forType(PermissionType type) {
    return switch (type) {
      PermissionType.camera => camera,
      PermissionType.photos || PermissionType.gallery => photos,
      PermissionType.storage || PermissionType.manageExternalStorage => storage,
      PermissionType.documents => documents,
      PermissionType.microphone => microphone,
      PermissionType.locationWhenInUse ||
      PermissionType.locationAlways => location,
      PermissionType.notifications => notifications,
      PermissionType.contacts => contacts,
      PermissionType.calendar => calendar,
      PermissionType.bluetooth || PermissionType.nearbyDevices => bluetooth,
      PermissionType.phone => phone,
      PermissionType.mediaLibrary => mediaLibrary,
    };
  }
}

/// Visual and text configuration for all permission-related UI.
///
/// Provide a custom instance to [PermissionsModule] at bootstrap to override
/// icons, copy, or both.
class PermissionTheme {
  const PermissionTheme({
    this.icons = const PermissionIcons(),
    this.texts = const PermissionTexts(),
    this.iconSize = 48.0,
    this.explanations = const {},
  });

  final PermissionIcons icons;
  final PermissionTexts texts;

  /// Size of the icon displayed in rationale / settings dialogs.
  final double iconSize;

  /// Per-permission [PermissionExplanation] overrides.
  ///
  /// When a [PermissionType] is absent, [explanationFor] composes a fallback
  /// from [icons] + [texts] so existing configurations keep working.
  final Map<PermissionType, PermissionExplanation> explanations;

  /// Resolves the [PermissionExplanation] for [type].
  ///
  /// Resolution order:
  ///  1. Explicit entry in [explanations].
  ///  2. Fallback composed from [texts] (rationale) + [icons].
  PermissionExplanation explanationFor(PermissionType type) {
    final explicit = explanations[type];
    if (explicit != null) return explicit;

    final rationale = texts.rationaleFor(type);
    return PermissionExplanation(
      title: rationale.title,
      description: rationale.message,
      icon: icons.forType(type),
    );
  }
}
