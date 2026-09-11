# permissions

Production-grade permissions platform for the Sanad monorepo.

This package is the **single source of truth** for all runtime permission
handling. Every feature depends on this package — no feature may import
`permission_handler` directly.

```
Asset Picker  ─┐
Maps          ─┤
QR Scanner    ─┤──▶  permissions  ──▶  permission_handler
Speech / Voice─┘
```

---

## Architecture

```
lib/src/
├── domain/
│   ├── entities/
│   │   ├── permission_result.dart      # Rich result type
│   │   ├── permission_request.dart     # Request value object
│   │   └── permission_group.dart       # Batch request container
│   ├── enums/
│   │   ├── permission_type.dart        # Strongly-typed permission identifiers
│   │   └── permission_status.dart      # Our own status model
│   └── services/
│       └── permission_service.dart     # Abstract service contract
├── infrastructure/
│   ├── providers/
│   │   └── permission_handler_provider.dart   # ONLY file that imports ph
│   └── implementations/
│       └── permission_service_impl.dart
├── presentation/
│   └── dialogs/
│       ├── permission_dialog.dart              # Base dialog content widget
│       ├── permission_rationale_dialog.dart    # Pre-request rationale sheet
│       └── permission_settings_dialog.dart     # Settings redirect sheet
├── config/
│   └── permission_config.dart          # PermissionConfig + PermissionPolicy
├── theme/
│   └── permission_theme.dart           # Icons, texts, sizing
├── di/
│   ├── permissions_di.dart             # GetIt registrations
│   └── permissions_module.dart         # FeatureModule entry point
└── permissions_facade.dart             # Static public API
```

Clean Architecture layers:
- **Domain** — pure Dart, zero Flutter/platform dependencies
- **Infrastructure** — wraps `permission_handler`; never leaks its types
- **Presentation** — dialogs built on the Design System
- **DI** — wires everything together via GetIt

---

## Bootstrap

Add `PermissionsModule` to the app's `ModuleRegistry` **before** any module
that uses permissions:

```dart
moduleRegistry = ModuleRegistry([
  PermissionsModule(),   // ← must come before auth, maps, asset_picker, etc.
  MapsModule(),
  AuthModule(),
  // ...
]);
await moduleRegistry.initAll();
```

### Custom configuration

```dart
PermissionsModule(
  config: PermissionConfig(
    defaultPolicy: PermissionPolicy(
      showRationale: true,
      showSettingsDialog: true,
      autoOpenSettings: false,
    ),
  ),
  theme: PermissionTheme(
    iconSize: 56,
    texts: PermissionTexts(
      allowButtonLabel: 'Grant Access',
      denyButtonLabel: 'Skip',
      rationaleMessages: {
        PermissionType.camera: PermissionRationaleText(
          title: 'Camera Required',
          message: 'Point your camera at a QR code to scan it.',
        ),
      },
    ),
  ),
)
```

---

## Public API

### `Permissions` facade

All features interact through the static `Permissions` class.

#### Check (no prompt)

```dart
final result = await Permissions.checkCamera();
if (result.isGranted) { /* already have it */ }
```

#### Request

```dart
final result = await Permissions.requestCamera();
if (!result.isGranted) return;
```

#### Batch request

```dart
final results = await Permissions.requestMany([
  PermissionType.camera,
  PermissionType.microphone,
]);
final cameraGranted = results[PermissionType.camera]?.isGranted ?? false;
```

#### Ensure (full UX flow — recommended)

The `ensure*` methods handle the entire flow automatically:
1. Already granted → return immediately
2. Denied + `showRationale: true` → show rationale sheet → request
3. Permanently denied + `showSettingsDialog: true` → show settings sheet

```dart
// Simplest usage — no dialogs (no BuildContext)
final result = await Permissions.ensureCamera();
if (!result.isGranted) return;

// With dialogs (pass context from a widget)
final result = await Permissions.ensureCamera(context: context);
if (!result.isGranted) return;

// Custom per-call policy
final result = await Permissions.ensureLocation(
  context: context,
  policy: const PermissionPolicy(showRationale: false),
);
```

#### Generic ensure

```dart
final result = await Permissions.ensure(
  PermissionType.contacts,
  context: context,
  rationaleTitle: 'Access Contacts',
  rationaleMessage: 'We need your contacts to invite teammates.',
);
```

#### Open settings

```dart
await Permissions.openSettings();
```

### `PermissionResult`

```dart
result.isGranted          // true for granted / limited / provisional
result.isDenied           // true for denied
result.isPermanentlyDenied
result.isRestricted
result.isLimited          // iOS limited photo access
result.canOpenSettings    // true when settings is the only fix
result.permission         // PermissionType
result.status             // PermissionStatus
```

---

## Permission Types

| Type | Android | iOS |
|---|---|---|
| `camera` | CAMERA | Camera |
| `photos` | READ_MEDIA_IMAGES (13+) | Photos |
| `gallery` | READ_EXTERNAL_STORAGE / storage | Photos |
| `storage` | READ/WRITE_EXTERNAL_STORAGE | — |
| `documents` | MANAGE_EXTERNAL_STORAGE | Photos |
| `microphone` | RECORD_AUDIO | Microphone |
| `locationWhenInUse` | ACCESS_FINE_LOCATION | Location When In Use |
| `locationAlways` | ACCESS_BACKGROUND_LOCATION | Location Always |
| `notifications` | POST_NOTIFICATIONS (13+) | Notifications |
| `contacts` | READ_CONTACTS | Contacts |
| `calendar` | READ/WRITE_CALENDAR | Calendar |
| `bluetooth` | BLUETOOTH | Bluetooth |
| `nearbyDevices` | NEARBY_WIFI_DEVICES | Bluetooth |
| `phone` | READ_PHONE_STATE | — |
| `mediaLibrary` | — | Media Library |
| `manageExternalStorage` | MANAGE_EXTERNAL_STORAGE | — |

---

## Adding a new permission

1. Add a value to `PermissionType` in
   `lib/src/domain/enums/permission_type.dart`.
2. Add the platform mapping in `PermissionHandlerProvider._toNative()`.
3. Add an icon in `PermissionIcons.forType()`.
4. Optionally add a default rationale text in `PermissionTexts`.
5. Optionally add a typed helper on the `Permissions` facade.
6. Update this README's permission table.

---

## Dependency Injection

The DI layer uses GetIt via the monorepo-wide `sl` singleton:

| Registered type | Scope | Implementation |
|---|---|---|
| `PermissionConfig` | Lazy singleton | From `PermissionsModule` constructor |
| `PermissionTheme` | Lazy singleton | From `PermissionsModule` constructor |
| `PermissionHandlerProvider` | Lazy singleton | `PermissionHandlerProvider()` |
| `PermissionService` | Lazy singleton | `PermissionServiceImpl` |

---

## Customisation

### Custom rationale texts per permission

```dart
PermissionTheme(
  texts: PermissionTexts(
    rationaleMessages: {
      PermissionType.location: PermissionRationaleText(
        title: 'Location Needed',
        message: 'Show nearby service providers on the map.',
      ),
    },
  ),
)
```

### Custom icons

```dart
PermissionTheme(
  icons: PermissionIcons(
    camera: MyIcons.camera,
    location: MyIcons.map,
  ),
)
```

### Per-request policy override

```dart
await Permissions.requestCamera(
  policy: const PermissionPolicy(
    showRationale: true,
    showSettingsDialog: false,
  ),
);
```

---

## Future extensibility

The architecture is designed so these can be added without breaking the public
API:

- **Permission analytics** — wrap `PermissionHandlerProvider` with an
  analytics decorator; register the decorator in `PermissionsDI`.
- **Permission caching** — add a cache layer between the service and provider.
- **Permission history** — record grant/deny events in `PermissionServiceImpl`.
- **Permission monitoring** — stream-based status watching via a new
  `watchPermission(PermissionType)` method on `PermissionService`.
- **OEM-specific behaviour** — extend `PermissionHandlerProvider` with
  manufacturer-specific checks.
- **Education screens** — add a `PermissionEducationPage` route to the module's
  `routes()` method.
