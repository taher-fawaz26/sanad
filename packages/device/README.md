# device

The single gateway to all device capabilities for the Sanad monorepo.

Every feature depends on this package for device info, app info, connectivity,
biometrics, clipboard, share, and URL launching. **No feature may import a
device plugin directly.**

```
Feature  ─┐
Feature  ─┤──▶  device  ──▶  device_info_plus / package_info_plus /
Feature  ─┘                  connectivity_plus / local_auth /
                             share_plus / url_launcher
```

The package is deliberately generic — it knows nothing about authentication,
registration, asset picking, or maps.

---

## Architecture

Clean Architecture, mirroring the `permissions` package:

```
lib/src/
├── domain/                      # pure Dart — no Flutter, no plugins
│   ├── entities/
│   │   ├── device_info_data.dart
│   │   ├── app_info_data.dart
│   │   ├── biometric_auth_result.dart
│   │   └── share_result.dart
│   ├── enums/
│   │   ├── connectivity_status.dart
│   │   ├── biometric_type.dart
│   │   ├── biometric_auth_status.dart
│   │   └── share_status.dart
│   └── services/                # one abstract contract per capability
│       ├── device_info_service.dart
│       ├── app_info_service.dart
│       ├── connectivity_service.dart
│       ├── biometric_service.dart
│       ├── clipboard_service.dart
│       ├── share_service.dart
│       └── url_launcher_service.dart
├── infrastructure/
│   ├── providers/               # THE ONLY files that import plugins
│   │   ├── device_info_provider.dart      (device_info_plus)
│   │   ├── app_info_provider.dart         (package_info_plus)
│   │   ├── connectivity_provider.dart     (connectivity_plus)
│   │   ├── biometric_provider.dart        (local_auth)
│   │   ├── clipboard_provider.dart        (flutter/services)
│   │   ├── share_provider.dart            (share_plus)
│   │   └── url_launcher_provider.dart     (url_launcher)
│   └── implementations/         # service impls, delegate to providers
├── config/
│   └── device_config.dart
├── di/
│   ├── device_di.dart           # GetIt registrations
│   └── device_module.dart       # FeatureModule entry point
└── device_facade.dart           # static `Device` public API
```

> **presentation/ and theme/** — reserved. The device package introduces no UI
> today. When a capability needs UI (e.g. a biometric prompt sheet), add it
> under `presentation/` using the `design_system` package, following the same
> pattern as `permissions`.

**Rule:** a plugin type never appears outside `infrastructure/providers/`.
Everything crossing a layer boundary is one of our own domain models.

---

## Bootstrap

Register `DeviceModule` in the app's `ModuleRegistry` at bootstrap:

```dart
moduleRegistry = ModuleRegistry([
  DeviceModule(),
  PermissionsModule(),
  // ... feature modules
]);
await moduleRegistry.initAll();
```

Custom configuration:

```dart
DeviceModule(
  config: DeviceConfig(
    defaultBiometricReason: 'Unlock Sanad',
    biometricOnlyByDefault: true,
  ),
)
```

---

## Public API — the `Device` facade

```dart
// Device & app info
final device = await Device.info();       // DeviceInfoData
final app = await Device.appInfo();        // AppInfoData

// Connectivity
final status = await Device.connectivityStatus();  // ConnectivityStatus
final online = await Device.isConnected();
Device.onConnectivityChanged().listen((s) { ... });

// Biometrics
if (await Device.isBiometricSupported()) {
  final result = await Device.authenticate(reason: 'Unlock');
  if (result.isSuccess) { ... }
}

// Clipboard
await Device.copy('hello');
final text = await Device.paste();
final has = await Device.clipboardHasData();
await Device.clearClipboard();

// Share
await Device.shareText('Check this out', subject: 'Sanad');
await Device.shareFiles(['/path/to/file.pdf']);
await Device.shareUri('https://sanad.app');

// URL launcher
await Device.openUrl('https://sanad.app');
await Device.openPhone('+971500000000');
await Device.openEmail('help@sanad.app', subject: 'Hi');
await Device.openSms('+971500000000', body: 'Hello');
await Device.openMaps('Dubai Mall');
```

Features never instantiate services manually — they only call `Device.*`.
Advanced consumers may still resolve a service directly from DI
(`sl<ConnectivityService>()`) when they need the raw contract.

---

## Domain models

| Model | Notes |
|---|---|
| `DeviceInfoData` | model, manufacturer, brand, osVersion, sdkVersion, isTablet, isPhysicalDevice, deviceId |
| `AppInfoData` | appName, packageName, version, buildNumber, installerStore |
| `ConnectivityStatus` | wifi, mobile, ethernet, vpn, bluetooth, other, none (+ `isConnected`) |
| `BiometricType` | face, fingerprint, iris, strong, weak |
| `BiometricAuthResult` / `BiometricAuthStatus` | success, failed, cancelled, notAvailable, notEnrolled, lockedOut, passcodeNotSet, error |
| `ShareResult` / `ShareStatus` | success, dismissed, unavailable |

No `permission_handler`, `local_auth`, `connectivity_plus`, etc. type is ever
exposed through these.

---

## Dependency Injection

`DeviceDI.init()` registers, as lazy singletons:

1. `DeviceConfig`
2. One provider per capability (plugin wrappers)
3. One service per capability (public contracts), each wired to its provider

`DeviceModule` (a `core` `FeatureModule`) calls `DeviceDI.init(config)` from
`registerDependencies()`.

---

## Platform notes

- **Android tablet detection** — `device_info_plus` exposes no reliable tablet
  flag; `isTablet` is `false` on Android (screen-size detection belongs to the
  UI layer). iOS tablet detection (iPad) is reliable.
- **Connectivity** — `connectivity_plus` returns a *list* of active transports;
  the provider collapses it to a single `ConnectivityStatus` by priority.
  `satellite` (plugin v7+) surfaces as `other`.
- **Biometrics** — platform exceptions are mapped to `BiometricAuthStatus`
  values, never rethrown into features.
- **Maps** — `openMaps` uses a universal Google Maps URL that resolves to the
  native maps app when installed, otherwise the browser (Android + iOS).

---

## Adding a new capability

1. Add domain model(s) under `domain/entities` / `domain/enums` (pure Dart).
2. Add an abstract `XxxService` under `domain/services`.
3. Add an `XxxProvider` under `infrastructure/providers` that wraps the plugin
   and maps to domain models. **This is the only place the plugin is imported.**
4. Add the plugin to `pubspec.yaml`.
5. Add `XxxServiceImpl` under `infrastructure/implementations`, delegating to
   the provider.
6. Register both in `DeviceDI.init()`.
7. Expose convenience methods on the `Device` facade.
8. Export the new public types from `device.dart`.
9. Add tests (mapping + impl + facade) and update this README.

---

## Testing

Covered:

- **Mapping** — connectivity result reduction, biometric type + error-code
  mapping, share status mapping.
- **Services / implementations** — every impl delegates correctly.
- **Facade** — `Device.*` resolves and delegates through DI; config fallback.
- **Config** — defaults and value equality.

Run:

```bash
flutter test packages/device
```
