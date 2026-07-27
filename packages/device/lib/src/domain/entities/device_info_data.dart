import 'package:equatable/equatable.dart';

/// Platform-agnostic snapshot of the physical device.
///
/// Fields that a given platform cannot supply are filled with empty strings /
/// sensible defaults by the provider so consumers never deal with nulls
/// unexpectedly.
class DeviceInfoData extends Equatable {
  const DeviceInfoData({
    required this.model,
    required this.manufacturer,
    required this.brand,
    required this.osVersion,
    required this.sdkVersion,
    required this.isTablet,
    required this.isPhysicalDevice,
    this.deviceId,
  });

  /// Marketing / hardware model name (e.g. "Pixel 8", "iPhone15,2").
  final String model;

  /// Manufacturer (e.g. "Google", "Apple"). Empty on iOS.
  final String manufacturer;

  /// Product brand (e.g. "google"). Empty on iOS.
  final String brand;

  /// OS version string (e.g. Android "14", iOS "17.5").
  final String osVersion;

  /// Platform SDK / API level. Android API level as a string; iOS mirrors
  /// [osVersion].
  final String sdkVersion;

  /// Best-effort tablet detection. Reliable on iOS (iPad); a heuristic on
  /// Android.
  final bool isTablet;

  /// `false` when running on a simulator / emulator.
  final bool isPhysicalDevice;

  /// A vendor-scoped identifier where the platform allows it. May be `null`.
  ///
  /// Note: this is NOT a stable hardware ID — on iOS it is the
  /// identifierForVendor, which resets when all vendor apps are uninstalled.
  final String? deviceId;

  @override
  List<Object?> get props => [
    model,
    manufacturer,
    brand,
    osVersion,
    sdkVersion,
    isTablet,
    isPhysicalDevice,
    deviceId,
  ];
}
